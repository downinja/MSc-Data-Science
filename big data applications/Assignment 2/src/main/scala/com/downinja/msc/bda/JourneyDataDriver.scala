package com.downinja.msc.bda

import org.apache.log4j.LogManager

import org.apache.spark._
import org.apache.spark.graphx._
import org.apache.spark.serializer._

import org.apache.spark.sql.Row;
import org.apache.spark.sql.functions._
import org.apache.spark.sql.SQLContext
import org.apache.spark.sql.types.{DoubleType,IntegerType,LongType,StructType,StructField,StringType};

object JourneyDataDriver {
  
  @transient lazy val log = org.apache.log4j.LogManager.getLogger("JourneyDataDriver")
  
  def main(args : Array[String]) {
  
    val inDirectory = args(0)  
    val outDirectory = args(1) 
    val journeysFile = args(2) 
    val pageRankTolerance = 0.0001
    
    log.info("Using inDirectory: " + inDirectory)
    log.info("Using outDirectory: " + outDirectory)
    log.info("Using journeysFile: " + journeysFile)
    log.info("Using pageRankTolerance: " + pageRankTolerance)
    
    // SparkConf needs a master URL to be specified - which is different when running on my 
    // home PC (in standalone mode) than when running on the DSM cluster. To avoid having to 
    // recompile/redeploy code per environment, I'm using either the "-Dspark.master=local"
    // system property, for local use, or else specifying "--master yarn" to the spark-submit 
    // job, on the cluster.
    val conf = new SparkConf()
      .setAppName("TFL CycleHire - GraphX Journey Data")
      .set("spark.serializer", classOf[KryoSerializer].getName)
    log.info("created SparkConf: " + conf.toDebugString)
 
    // Create our SparkContext. (We're not doing this inside a REPL shell, so it doesn't get
    // done for us.)
    val sc = new SparkContext(conf)
    log.info("created SparkContext: " + sc)
    
    // Also create a SQLContext for querying DataFrames later.
    val sqlContext = new SQLContext(sc)
    log.info("created SQLContext")
    
    // Read in the static data for the docking stations (IDs, names, 
    // longitudes and latitudes) - converting them to graphx Vertices
    val vertices = sc.textFile(inDirectory + "stations.csv")
      .filter(line => !line.startsWith("id,")) // skip header
      .map(JourneyDataUtil.createVertex)
    
    // Read in the journey data, converting each journey to a graphx Edge
    val edges = sc.textFile(inDirectory + journeysFile)
      .filter(line => !line.startsWith(",RentalId")) // skip header
      .map(JourneyDataUtil.createEdge)
    edges.cache
    
    // Create/cache our primary Graph object
    val journeysGraph = Graph(vertices, edges)
    journeysGraph.cache
    
    // Create lookup tables of the in/out degrees for each vertex,
    // as this will be more convenient later when constructing our
    // SQL DataFrame.
    val byInDegree = journeysGraph.inDegrees.collectAsMap
    val byOutDegree = journeysGraph.outDegrees.collectAsMap
    
    // Now call the pageRank method to rank each vertex (docking station)
    // in the graph (cycle network). This will continue to loop round the 
    // algorithm unless/until the specified tolerance is met.  
    val verticesWithRank = journeysGraph
      .pageRank(pageRankTolerance).vertices
      .join(journeysGraph.vertices)
    verticesWithRank.cache
   
    // Although we could query the graph, using a functional approach, 
    // it's also useful to construct a DataFrame so that we can execute
    // SQL queries for basic ordering and aggregation (rather than 
    // anything more suited to, or requiring, graph traversal).
    val schema = StructType(Array(
      StructField("ID", LongType, true),
      StructField("NAME", StringType, true),
      StructField("RANK", DoubleType, true),
      StructField("IN_DEGREE", IntegerType, true),
      StructField("OUT_DEGREE", IntegerType, true)
    ))
 
    // Helper function for converting verticesWithRank to a DataFrame, in
    // conjuction with the lookup tables for in/out degree by VertexId
    def createRow(vertexWithRank: (VertexId,(Double, Map[String, String]))): Row = {
      val vertexId = vertexWithRank._1.longValue
      val name = vertexWithRank._2._2.get("name").get
      val rank = vertexWithRank._2._1
      val inDegree = byInDegree.get(vertexId).getOrElse(0)
      val outDegree = byOutDegree.get(vertexId).getOrElse(0)
      return Row(vertexId, name, rank, inDegree, outDegree);
    }
    
    // Now we can create a DataFrame from our graph/ranked data.
    val rowRDD = verticesWithRank.map(createRow)
    val verticesDataFrame = sqlContext.createDataFrame(rowRDD, schema)
    verticesDataFrame.registerTempTable("VERTICES")
    
    // A simple query is to sort the vertices by rank, in descending
    // order. Then we can write this to a csv file for use outside
    // this application.
    val columns = "ID,NAME,RANK,IN_DEGREE,OUT_DEGREE"
    var sql = "SELECT " + columns + " FROM VERTICES ORDER BY RANK DESC"
    var dataFrame = sqlContext.sql(sql)
    JourneyDataUtil.dataFrameToCsv(outDirectory + "rankedJourneys.csv", dataFrame)
  
    // Similarly, we can use SQL to join the DataFrame to itself and calculate
    // differences in RANK and IN_DEGREE - where these are of interest (e.g.
    // where one vertex has a higher IN_DEGREE than another, but has been 
    // assigned a lower RANK by the pageRank algorithm). 
    sql = 
      "SELECT " + 
          "a.ID, " + 
          "b.ID, " + 
          "(b.IN_DEGREE - a.IN_DEGREE) as DEGREE_DIFF, " +
          "(a.RANK - b.RANK) AS RANK_DIFF " +
      "FROM " + 
          "VERTICES a, " + 
          "VERTICES b " + 
      "WHERE " + 
          "a.RANK > b.RANK " + 
          "and b.IN_DEGREE > a.IN_DEGREE " 
      
    dataFrame = sqlContext.sql(sql)
    JourneyDataUtil.dataFrameToCsv(outDirectory + "rankDiffs.csv", dataFrame)
    
    // And in order to summarise these interesting events, we can sum over the 
    // IN_DEGREE and RANK values and pick out e.g. the vertex with the highest 
    // total increase in rank over those vertices which have a larger value of 
    // IN_DEGREE.  
    sql = 
      "SELECT " + 
          "a.ID, " + 
          "SUM(b.IN_DEGREE - a.IN_DEGREE) as TOTAL_DEGREE_DIFF, " +
          "SUM(a.RANK - b.RANK) AS TOTAL_RANK_DIFF " +
      "FROM " + 
          "VERTICES a, " + 
          "VERTICES b " + 
      "WHERE " + 
          "a.RANK > b.RANK " + 
          "AND b.IN_DEGREE > a.IN_DEGREE " +
          "GROUP BY a.ID"

    dataFrame = sqlContext.sql(sql)
    dataFrame.cache
    JourneyDataUtil.dataFrameToCsv(outDirectory + "highestRankedDespiteLowerInDegree.csv", dataFrame)
    // Store the first one in the results so we can use it for personalisedPageRank later
    val highestRankedDespiteLowerInDegree = dataFrame.orderBy(desc("TOTAL_RANK_DIFF")).take(1)(0).getAs[Long](0)
    log.info("highestRankedDespiteLowerInDegree = " + highestRankedDespiteLowerInDegree)
     
    // Similarly, find the vertex which "loses out" the most, in terms of RANK,  
    // to those vertices which have a lower value of IN_DEGREE.
    sql = 
      "SELECT " + 
          "b.ID, " + 
          "SUM(b.IN_DEGREE - a.IN_DEGREE) as TOTAL_DEGREE_DIFF, " +
          "SUM(a.RANK - b.RANK) AS TOTAL_RANK_DIFF " +
      "FROM " + 
          "VERTICES a, " + 
          "VERTICES b " + 
      "WHERE " + 
          "a.RANK > b.RANK " + 
          "AND b.IN_DEGREE > a.IN_DEGREE " +
          "GROUP BY b.ID"

    dataFrame = sqlContext.sql(sql)
    dataFrame.cache
    JourneyDataUtil.dataFrameToCsv(outDirectory + "lowestRankedDespiteHigherInDegree.csv", dataFrame)
    // Store the first one in the results so we can use it for personalisedPageRank later
    val lowestRankedDespiteHigherInDegree = dataFrame.orderBy(desc("TOTAL_RANK_DIFF")).take(1)(0).getAs[Long](0)
    log.info("lowestRankedDespiteHigherInDegree = " + lowestRankedDespiteHigherInDegree)
   
    // Now we move on to creating Gephi format files for visualisation. We don't want to specify
    // every journey from A to B, as plotting ~9 million lines on a chart isn't helpful. But we
    // can summarise by totting up all journeys from A to B, and using this total as the weight
    // of the respective Edge.
    
    val journeyCounts = edges
      // There's probably a function to do this, but am just using map/reduce to sum  
      // each journey between A and B and then create a lookup table. Potentially it's
      // riskier to collect Edges in the driver app, but out of a possible ~332k 
      // combinations of A and B it's unlikely that we're going to pull back enough to
      // run out of memory.
      .map(JourneyDataUtil.countJourney)
      .reduceByKey(_+_)
      .collectAsMap
      
    val edgesWithCounts = edges
      // Similarly there may be an "add attribute" function that I'm not aware of,
      // but I'm just using the above lookup table 
      .map(edge => JourneyDataUtil.createEdgeWithJourneyCount(edge, journeyCounts))
      .distinct
    edgesWithCounts.cache
    
    // Output the full network graph in GEFX format. Sort of. It still needs to be loaded 
    // into Gephi and exported for use by e.g. Javascript libraries - since Gephi adds 
    // additional attributes for display purposes. Haven't quite figured out how to 
    // calculate them directly. 
    JourneyDataUtil.graphToFile(outDirectory + "rankedJourneys.gexf", Graph(verticesWithRank, edgesWithCounts))
    
    // Also output a cut-down network graph of just those journeys involving our "highest ranked
    // despite not having the highest in-degree" vertex, from earlier. In case it's useful.
    val ppr1 = journeysGraph.personalizedPageRank(highestRankedDespiteLowerInDegree, pageRankTolerance)
      .vertices
      .join(journeysGraph.vertices)
    
    val pprEdges1 = edgesWithCounts.filter(
        edge => 
           edge.srcId == highestRankedDespiteLowerInDegree || 
           edge.dstId == highestRankedDespiteLowerInDegree)  
 
    JourneyDataUtil.graphToFile(outDirectory + "highestRankedDespiteLowerInDegree.gexf", Graph(ppr1, pprEdges1))

    // And the same for our "not highest ranked, despite having a higher in-degree than 
    // more highly ranked vertices" vertex.
    val ppr2 = journeysGraph.personalizedPageRank(lowestRankedDespiteHigherInDegree, pageRankTolerance)
      .vertices
      .join(journeysGraph.vertices)
    
    val pprEdges2 = edgesWithCounts.filter(
        edge => 
           edge.srcId == lowestRankedDespiteHigherInDegree || 
           edge.dstId == lowestRankedDespiteHigherInDegree)  
      
    JourneyDataUtil.graphToFile(outDirectory + "lowestRankedDespiteHigherInDegree.gexf", Graph(ppr2, pprEdges2))
      
  }
  
}