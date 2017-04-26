package com.downinja.msc.bda

import org.apache.spark.graphx.Edge
import org.apache.spark.graphx.Graph
import org.apache.spark.sql.DataFrame

/*
 * Util functions for use with the JourneyDataDriver class. Note that these
 * functions are passed around with lambdas, so should be stateless (to avoid
 * passing the enclosing class around with them). 
 */

object JourneyDataUtil {

    // This is for use inside a map/reduce implementation of journey count.
    // It just emits "1" for every combination of start and end station found
    // in the graph.
    def countJourney(journey: Edge[Int]): ((Long, Long), Int) = {
        val startStationId = journey.srcId
        val endStationId = journey.dstId
        return ((startStationId, endStationId),1)
    }
  
    // This creates an Edge for each line of the (csv) journeys data.
    def createEdge(line: String) : Edge[Int] = {
      val array = line.split(',')
      val sourceId = array(6).toLong
      val destId = array(4).toDouble.toLong
      // could add attributes here such as bikeId, timestamp etc
      return Edge(sourceId, destId, 1); // "1" is just a dummy attribute, since GraphX requires there to be one
    }
          
    // This decorates an Edge with the number of times it's been traversed in the graph - that is, 
    // its journey count. Possibly inefficient to pass in a lookup table (Map) of journey counts, as
    // this will need to be replicated out to each cluster machine that uses this function (?)
    def createEdgeWithJourneyCount(edge: Edge[Int], map: scala.collection.Map[(Long,Long), Int]): Edge[Int] = {
        return Edge(edge.srcId, edge.dstId, map.get((edge.srcId, edge.dstId)).get)
    }
    
    // This creates a vertex for every location station in the (csv) docking stations data.
    def createVertex(line: String): (Long, Map[String, String]) = {
      // http://stackoverflow.com/questions/1757065/java-splitting-a-comma-separated-string-but-ignoring-commas-in-quotes
      val array = line.split(",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)")
      val id = array(0).toLong
      val name = array(1)
      val lat = array(3)
      val long = array(4)
      val attributes = Map(
          "name" -> name, 
          "latitude" -> lat, 
          "longitude" -> long
      ) 
      return (id, attributes)
    }

    // This just writes out a DataFrame in csv format. Evidently this is built-in
    // from Spark 1.6, but we're running 1.4.1 on the cluster.
    def dataFrameToCsv(fileName: String, dataFrame: DataFrame) = {
      val csvFile = new java.io.File(fileName)
      csvFile.createNewFile();
      val pw = new java.io.PrintWriter(csvFile)
      pw.write(dataFrame.columns.map(columnName => columnName + ",").mkString  + "\n")
      val results = dataFrame.map(row => row.mkString("",",","")+",\n").collect.mkString;
      pw.write(results)
      pw.close
    }

    // This writes out a Graph in GEXF format (using the helper function from the
    // Manning "Spark GraphX in Action" book below).
    def graphToFile(fileName: String, graph:Graph[(Double, Map[String, String]),Int]) = {
      val gephiFile = new java.io.File(fileName)
      gephiFile.createNewFile();
      val pw = new java.io.PrintWriter(gephiFile)
      pw.write(JourneyDataUtil.toGexf(graph))
      pw.close
    }
  
    /*
 		* Adapted from: 
 		* https://manning-content.s3.amazonaws.com/download/3/6311f4a-a8af-45e2-80d1-f4689c23d802/SparkGraphXInActionSourceCode.zip
 		*/
    def toGexf(g:Graph[(Double, Map[String, String]),Int]) =
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
      "<gexf xmlns=\"http://www.gexf.net/1.2draft\" version=\"1.2\">\n" +
      "  <graph mode=\"static\" defaultedgetype=\"directed\">\n" +
      "    <attributes class=\"node\">\n" +
      "      <attribute id=\"0\" title=\"latitude\" type=\"double\"/>\n" +
      "      <attribute id=\"1\" title=\"longitude\" type=\"double\"/>\n" +
      "      <attribute id=\"2\" title=\"rank\" type=\"float\"/>\n" +
      "    </attributes>\n" +
      "    <nodes>\n" +
              g.vertices.sortBy(vertex => vertex._2._1, ascending = false).map(v => 
      "      <node id=\"" + v._1 + "\" label=" +
              v._2._2.get("name").get.replace("&", "&amp;") + ">\n" + 
      "        <attvalues>\n" +
      "          <attvalue for=\"0\" value=\"" + v._2._2.get("latitude").get + "\"/>\n" +
      "          <attvalue for=\"1\" value=\"" + v._2._2.get("longitude").get + "\"/>\n" +
      "          <attvalue for=\"2\" value=\"" + v._2._1 + "\"/>\n" +
      "        </attvalues>\n" +
      "      </node>\n").collect.mkString +
      "    </nodes>\n" +
      "    <edges>\n" +
              g.edges.sortBy(edge => edge.attr, ascending = false).map(e => 
      "      <edge source=\"" + e.srcId + "\" " + 
                  "target=\"" + e.dstId + "\" " + 
                  "label=\"" + e.attr + "\" " + 
                  "weight=\"" + e.attr.toFloat + "\"" + 
             "/>\n").collect.mkString +
      "    </edges>\n" +
      "  </graph>\n" +
      "</gexf>"
  }