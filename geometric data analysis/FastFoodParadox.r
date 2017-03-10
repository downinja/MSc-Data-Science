# Initial set-up
library(FactoMineR)
setwd("C:/Users/john/dev/goldsmiths/gda")

# Read in the data table
data <- read.csv(
  file = "FastFoodParadox.csv",
  header = TRUE
)

# Columns 1-20 are raw numeric responses from (presumed) likert scale questions. To 
# perform MCA, these need to be converted into factors. And following the lead from
# http://enquirer.free.fr/case-studies/Fast-Food%20Paradox/Fast-Food%20Paradox.R, we
# are also converting these to the equivalent textural responses, to aid interpretation.

# Creating variables for each type of likert scale, for re-use across questions.
likert1 <- c('very bad','bad','normal','good','very good')
likert2 <- c('not expensive','a little expensive','average','quite expensive','very expensive')
likert3 <- c('not balanced','badly balanced','average','quite well balanced','well balanced')
likert4 <- c('not at all','not much','average','quite a lot','enormously')
likert5 <- c('disagree','slightly disagree','neither agree nor disagree','slightly agree','agree')
likert6 <- c('no pleasure','not much pleasure','average','quite a lot pleasure','great pleasure')
likert7 <- c('not convivial','not much convivial','average','quite convivial','very convivial')
likert8 <- c('not practical','average','quite practical','very practical')
likert9 <- c('nothing pleasant','few pleasant things','average','some pleasant things','a lot of pleasant things')
likert10 <- c('not at all','a little','average','not much')
likert11 <- c('never','rarely','sometimes','often','always')

# Now convert each of columns 1-20 to textual factors.
data$Image <- factor(data$Image, labels = likert1)
data$Expensive <- factor(data$Expensive, labels = likert2)
data$Good.value.for.money <- factor(data$Good.value.for.money, labels = likert1)
data$Kind.of.consumer <- factor(data$Kind.of.consumer, labels = likert1)
data$Not.balanced <- factor(data$Not.balanced, labels =  likert3)
data$Products.assessment <- factor(data$Products.assessment, labels = likert4)
data$Don.t.eat.enough <- factor(data$Don.t.eat.enough, labels = likert5)
data$Bad.nutritionnal.quality <- factor(data$Bad.nutritionnal.quality, labels = likert5)
data$Pleasure <- factor(data$Pleasure, labels = likert6)
data$Agree.with.pollution <- factor(data$Agree.with.pollution, labels = likert5)
data$Convivial <- factor(data$Convivial, labels = likert7)
data$Practical <- factor(data$Practical, labels = likert8 )
data$Play.side <- factor(data$Play.side, labels = likert9)
data$Not.varied.enough <- factor(data$Not.varied.enough, labels = likert5)
data$Satisfy.everybody <- factor(data$Satisfy.everybody, labels = likert5)
data$A.lack.of.it <- factor(data$A.lack.of.it, labels = likert4)
data$Feel.bad <- factor(data$Feel.bad, labels = likert10)
data$Food.adjust <- factor(data$Food.adjust, labels = likert11)
data$Unstatisfying.products <- factor(data$Unstatisfying.products, labels = likert5)
data$Cheaper.meal <- factor(data$Cheaper.meal, labels = likert5)

# Also renaming the columns, as the translations from French are not always helpful.
colnames(data)[1]="Image"
colnames(data)[2]="HowExpensive"
colnames(data)[3]="ValueForMoney"
colnames(data)[4]="ConsumerType"
colnames(data)[5]="HowWellBalanced"
colnames(data)[6]="Appreciation"
colnames(data)[7]="AreSmallPortions"    
colnames(data)[8]="IsPoorNutrition"      
colnames(data)[9]="HowPleasurable"
colnames(data)[10]="PollutesEnvironment"
colnames(data)[11]="HowConvivial"
colnames(data)[12]="HowPractical"
colnames(data)[13]="PleasentSide"
colnames(data)[14]="NotVariedEnough"
colnames(data)[15]="SuitEverybody"
colnames(data)[16]="WouldBeMissed"
colnames(data)[17]="FeelBadAfter"
colnames(data)[18]="DietAfter"
colnames(data)[19]="Unsatisfying"
colnames(data)[20]="IsCheaper"
colnames(data)[21]="Overall"
colnames(data)[22]="Morning"              #Active
colnames(data)[23]="Lunch"                #Active
colnames(data)[24]="Afternoon"            #Active
colnames(data)[25]="Evening"              #Active
colnames(data)[26]="Night"                #Active
colnames(data)[27]="WeekOrWeekend"        #Active
colnames(data)[28]="Friends"              #Active
colnames(data)[29]="Couple"               #Active
colnames(data)[30]="Alone"                #Active
colnames(data)[31]="Family"               #Active
colnames(data)[32]="EatInOrTakeaway"      #Active
colnames(data)[33]="Burger"               #Active
colnames(data)[34]="Nuggets"              #Active
colnames(data)[35]="Salads"               #Active
colnames(data)[36]="Soda"                 #Active
colnames(data)[37]="Water"                #Active
colnames(data)[38]="Juice"                #Active
colnames(data)[39]="DietSoda"             #Active
colnames(data)[40]="Chips"                #Active
colnames(data)[41]="Fruits"               #Active
colnames(data)[42]="IceCream"             #Active
colnames(data)[43]="Dessert"              #Active
colnames(data)[44]="Expenditure"          #Active
colnames(data)[45]="Brand"                #Active
colnames(data)[46]="Gender"
colnames(data)[47]="RegularSports"
colnames(data)[48]="Location"

active <- c(22:45)
quali.sup <- c(1:21,46:48)

# Check summary stats (looking for e.g. low response frequencies)
print(summary(data[, active]))

# Collapse Expenditure categories into two
levels(data$Expenditure) <- c("less than 8 Euros", "more than 8 Euros", "less than 8 Euros", "more than 8 Euros")

# Re-check modified summary stats
print(summary(data[, active]))

# Perform the MCA
data.mca <- MCA(
  X = data,
  level.ventil = 0.05, # since we can't automatically combine the other Yes|No categories
  quali.sup = quali.sup,
  graph = FALSE
)

# Check summary and dimdesc
print(summary(data.mca))
print(dimdesc(data.mca))

# Extract info from the MCA response model into more user-friendly variables
num.ind <- dim(data)[1]
num.categories <- dim(data.mca$var$contrib)[1]
num.dimensions <- dim(data.mca$eig)[1]
max.variance <- ceiling(max(data.mca$eig[[2]]))
ind.coords <- data.mca$ind$coord
sup.coords <- data.mca$quali.sup$coord
cat.names <- rownames(data.mca$var$coord)
sup.cat.names <- rownames(sup.coords)	   

# Check the number of dimensions discovered / percentage of variance/inertia explained by each
print(data.mca$eig)

# Barplot of the above
barplot(
  data.mca$eig[[2]],
  main = "% of variance explained by each dimension",
  xlab = "dimension",
  names = as.character(1:num.dimensions),
  ylab = "% variance",
  ylim = c(0, 10)
)

#	Invg cloud of categories.
plot(
  x = data.mca,
  invisible = c("ind", "quali.sup"),
  title = "Cloud of categories projected onto dimensions 1 and 2",
  habillage = "quali",
  autoLab = "yes",
  axes = c(1,2),
  cex = 0.9
)

plot(
  x = data.mca,
  invisible = c("ind", "quali.sup"),
  title = "Cloud of categories projected onto dimensions 2 and 3",
  habillage = "quali",
  autoLab = "yes",
  axes = c(2,3),
  cex = 0.9
)

# Helper function for investigations using supplementary categories
plot_with_sup <- function(
  dim1,
  dim2,
  sup.names,
  sup.label) {
  
  title = sprintf("Categories projected onto dimensions %d & %d, with %s as supplementary", dim1, dim2, sup.label)
  
  plot(
    x = data.mca,	   
    invisible = c("ind"),	   
    col.var = "#ef8a62",
    title = title,
    col.quali.sup = "black",	   	   	   	   
    cex = 0.9,
    axes = c(dim1, dim2),
    selectMod = c(sup.names, cat.names)
  )
  points(
    sup.coords[sup.names, dim1:dim2], 
    type = "l"
  )
}

# Supplementary - Gender
sup.cat.names.gender = c("M","F")
plot_with_sup(1, 2, sup.cat.names.gender, "Gender")
plot_with_sup(2, 3, sup.cat.names.gender, "Gender")

# Supplementary - Image
sup.cat.names.image = c("Image_very bad","Image_bad","Image_normal","Image_good")
plot_with_sup(1, 2, sup.cat.names.image, "Image")
plot_with_sup(2, 3, sup.cat.names.image, "Image")

# Supplementary - Appreciation
sup.cat.names.appreciation = c(
  "Appreciation_not much",
  "Appreciation_average",
  "Appreciation_quite a lot",
  "Appreciation_enormously"
)
plot_with_sup(1, 2, sup.cat.names.appreciation, "Appreciation")

# Supplementary - ConsumerType
sup.cat.names.consumer = c(
  "ConsumerType_very bad",
  "ConsumerType_bad",
  "ConsumerType_normal",
  "ConsumerType_good"
)
plot_with_sup(1, 2, sup.cat.names.consumer, "ConsumerType")

# Cloud of individuals
plot(
  x = data.mca,
  choix = "ind",
  col.ind = "#ef8a62",
  invisible = c("var", "quali.sup"),
  title = "Cloud of 166 individuals projected onto dimensions 1 and 2",
  axes = c(1,2),
  label = "none"
)

# Helper function
plot_with_landmarks = function(
  dim1,
  dim2,
  landmarks
  ) {
  
  title = sprintf(
    "Cloud of %d individuals projected on dimensions %d and %d, with landmarks", num.ind, dim1, dim2)
  
  plot(
    x = data.mca,	   
    choix = "ind",	   
    invisible = c("var", "quali.sup"),	   
    title = title,
    label = "none",
    axes = c(dim1, dim2),
    cex = 0.5
  )	   
  text(
    x = data.mca$ind$coord[landmarks,dim1:dim2],	   
    y = as.character(landmarks),
    col = "#ef8a62",
    cex = 1.1
  )
}

#	Dimensions 1 and 2.
landmarkind12 <- c(10, 19, 62, 97) # each ends of each axis
print(data[landmarkind12,active])
plot_with_landmarks(1, 2, landmarkind12)

#	Dimensions 2 and 3.
landmarkind23 <- c(46, 83, 143, 149)
print(data[landmarkind23, active])
plot_with_landmarks(2, 3, landmarkind23)

# Subclouds

# helper function

plot_subclouds = function(
  dim1,
  dim2,
  group1,
  group2,
  group1text,
  group2text) {

  title = sprintf(
    "Cloud of %d individuals projected on dimensions %d and %d: blue = %s, red = %s",
      num.ind, dim1, dim2, group1text, group2text
  )
  
  plot(
    x = data.mca,
    choix = "ind",	   
    invisible = c("var", "quali.sup"),	   
    title = title,
    label = "none",
    axes = c(dim1,dim2),
    col.ind = "grey"
  )
  text(
    x = ind.coords[group1,dim1:dim2],	   
    "+",	   
    col = "red",	   
    cex = 0.8
  )	   
  text(
    x = ind.coords[group2,dim1:dim2],	   
    "o",	   
    col="blue",	   
    cex=0.8
  )
}

#	Subclouds - ConsumerType.	   	   
indBadVeryBad <- rep(FALSE, num.ind)
indBadVeryBad[data[, "ConsumerType"] == "very bad"] <- TRUE
indBadVeryBad[data[, "ConsumerType"] == "bad"] <- TRUE

indGoodVeryGood <- rep(FALSE, num.ind)
indGoodVeryGood[data[, "ConsumerType"] == "good"] <- TRUE
indGoodVeryGood[data[, "ConsumerType"] == "very good"] <- TRUE
print(length(indBadVeryBad[indBadVeryBad]))
print(length(indGoodVeryGood[indGoodVeryGood]))

plot_subclouds(1, 2, indBadVeryBad, indGoodVeryGood, "good consumer", "bad consumer")

#	Subclouds - WeekOrWeekend.
indWeek <- rep(FALSE, num.ind)
indWeek[data[, "WeekOrWeekend"] == "Week"] <- TRUE
indWeekend <- rep(FALSE, num.ind)
indWeekend[data[, "WeekOrWeekend"] == "Week-end"] <- TRUE
print(length(indWeek[indWeek]))
print(length(indWeekend[indWeekend]))

plot_subclouds(1, 2, indWeek, indWeekend, "weekday", "weekend")
plot_subclouds(2, 3, indWeek, indWeekend, "weekday", "weekend")

#	Subclouds - EatInOrTakeaway.
indEatIn <- rep(FALSE, num.ind)
indEatIn[data[, "EatInOrTakeaway"] == "On the premises"] <- TRUE
indTakeAway <- rep(FALSE, num.ind)
indTakeAway[data[, "EatInOrTakeaway"] == "Take-away"] <- TRUE
print(length(indEatIn[indEatIn]))
print(length(indTakeAway[indTakeAway]))

plot_subclouds(1, 2, indEatIn, indTakeAway, "eat-in", "take-away")
plot_subclouds(2, 3, indEatIn, indTakeAway, "eat-in", "take-away")

#	Subclouds - Lunch vs Not Lunch.
indLunch <- rep(FALSE, num.ind)
indLunch[data[, "Lunch"] == "Yes"] <- TRUE
indNotLunch <- rep(FALSE, num.ind)
indNotLunch[data[, "Lunch"] == "No"] <- TRUE
print(length(indLunch[indLunch]))
print(length(indNotLunch[indNotLunch]))

plot_subclouds(1, 2, indLunch, indNotLunch, "lunch", "not lunch")
plot_subclouds(2, 3, indLunch, indNotLunch, "lunch", "not lunch")

#	Contributions of categories to dimensions.

# Top 15 dimension 1 & 2.
plot(
  x = data.mca,	   
  invisible = c("ind", "quali.sup"),
  title = "Top 15 categories contributing to dimensions 1 and 2",
  habillage = "quali",
  selectMod = "contrib 15"
)

# Top 15 dimension 2 & 3.
plot(
  x = data.mca,	   
  invisible = c("ind", "quali.sup"),
  title = "Top 15 categories contributing to dimensions 2 and 3",
  habillage = "quali",
  axes = c(2,3),
  selectMod = "contrib 15"
)

#	Find categories which contribute more than the average - to a single dimension.

# Dimension 1
avg.contr <- 100 / num.categories
dim1.contr <- data.mca$var$contr[,1]
dim1.above.avg.contr <- dim1.contr[dim1.contr > avg.contr]
dim1.above.avg.contr.names = names(dim1.above.avg.contr)
print(round(dim1.above.avg.contr, digits = 1))

# 11 categories with total 81.37% contribution
print(
  sum(data.mca$var$contr[dim1.above.avg.contr.names,1])
)

plot(
  x = data.mca,	   
  invisible = c("ind", "quali.sup", "ind.sup"),	   
  selectMod = dim1.above.avg.contr.names,
  habillage = "quali",	   
  autoLab = "yes",
  title = "11 categories with above average contribution to dimension 1",
  cex = 1.0
)	   
mtext(
  side = 2,
  text = "Frequent Customer",	   
  col = "brown",
  font = 4,
  cex = 1.3
)	   
mtext(
  side = 4,	  
  text = "Infrequent Customer",
  col = "brown",
  font = 4,
  cex = 1.3
)

dim2.contr <- data.mca$var$contr[,2]
dim2.above.avg.contr <- dim2.contr[dim2.contr > avg.contr]
dim2.above.avg.contr.names = names(dim2.above.avg.contr)
print(round(dim2.above.avg.contr, digits = 1))

# 11 categories with total 83.88% contribution to dimension 2
print(
  sum(data.mca$var$contr[dim2.above.avg.contr.names,2])
)

plot(
  x = data.mca,	   
  invisible = c("ind", "quali.sup", "ind.sup"),	   
  selectMod = c(dim2.above.avg.contr.names, "Alone_No"),
  habillage = "quali",	   
  autoLab = "yes",
  title = "11 categories with above average contribution to dimension 2",
  cex = 1.0
)	   
mtext(
  side = 3,
  text = "Couple Weekday Take-Out",	   
  col = "brown",
  font = 4,
  cex = 1.3
)	   
mtext(
  side = 1,	  
  text = "Solo Weekend Eat-In",
  col = "brown",
  font = 4,
  cex = 1.3
)

# Dimension 3
dim3.contr <- data.mca$var$contr[,3]
dim3.above.avg.contr <- dim3.contr[dim3.contr > avg.contr]
dim3.above.avg.contr.names = names(dim3.above.avg.contr)
print(round(dim3.above.avg.contr, digits = 1))

# 11 categories with total 82.28% contribution to dimension 3
print(
  sum(data.mca$var$contr[dim3.above.avg.contr.names,3])
)

plot(
  x = data.mca,	   
  invisible = c("ind", "quali.sup", "ind.sup"),	   
  selectMod = dim3.above.avg.contr.names,
  habillage = "quali",	   
  axes = c(3,4),
  autoLab = "yes",
  title = "11 categories with above average contribution to dimension 3",
  cex = 1.0
)
mtext(
  side = 4,
  text = "Family eat-in lunch",
  col = "brown",
  font = 4,
  cex = 1.3
)	   
mtext(
  side = 2,	  
  text = "Not family, not lunch, take-away",
  col = "brown",
  font = 4,
  cex = 1.3
)


#	Concentration Ellipses.	
plotellipses(
  model = data.mca,	   
  keepvar = "ConsumerType",
  label = "none",	   
  means = "FALSE",
  axes = c(1,2)
)

plotellipses(
  model = data.mca,	   
  keepvar = "WeekOrWeekend",
  label = "none",	   
  means = "FALSE",
  axes = c(1,2)
)

plotellipses(
  model = data.mca,	   
  keepvar = "Family",	   
  label = "none",	   
  means = "FALSE",
  axes = c(2,3)
)

plotellipses(
  model = data.mca,	   
  keepvar = "Lunch",
  label = "none",	   
  means = "FALSE",
  axes = c(2,3)
)

#	Hierarchical clustering.
res.hc.ind <- HCPC(data.mca,	nb.clust=5)
print(res.hc.ind)

res.hc.var <- HCPC(data.frame(data.mca$var$coord, nb.clust=-1))
print(res.hc.var)
