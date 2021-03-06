---
##title: "PA1_template"
##output: html_document
---

##Code for reading in the dataset and/or processing the data
##Unzip download file

setwd("C:/Users/gregg.abramovich/Desktop/R Notes!")
unzip("repdata-data-activity.zip")

##prep required packages

library(data.table)
library(ggplot2)
library(knitr)
library(plyr)
library(lattice)

##When writing code chunks in the R markdown document, always use echo = TRUE so that someone else will be able to read the code.

opts_chunk$set(echo = TRUE, results = 'hold')

activityDataSet = read.csv("activity.csv")

##variables:
##steps: Number of steps taking in a 5-minute interval (missing values are coded as NA)
##date: The date on which the measurement was taken in YYYY-MM-DD format
##interval: Identifier for the 5-minute interval in which measurement was taken

##need to make sure the date variable is converted to the date datatype

activityDataSet$date <- as.Date(activityDataSet$date) 

##str(activityDataSet)
##'data.frame':	17568 obs. of  3 variables:
##  $ steps   : int  NA NA NA NA NA NA NA NA NA NA ...
##$ date    : Date, format: "2012-10-01" "2012-10-01" "2012-10-01" "2012-10-01" ...
##$ interval: int  0 5 10 15 20 25 30 35 40 45 ...
##date is now of datatype date and steps and interval are of the int datatype

##Histogram of the total number of steps taken each day

##Sum up number of steps occuring on each day

totalStepsPerDay <- aggregate(steps ~ date, activityDataSet, sum)
totalStepsPerDay <- data.frame(totalStepsPerDay) ##convert to data frame for grpahing package
##> str(totalStepsPerDay)
##'data.frame':	53 obs. of  2 variables:
##  $ date : Date, format: "2012-10-02" "2012-10-03" "2012-10-04" "2012-10-05" ...
##  $ steps: int  126 11352 12116 13294 15420 11015 12811 9900 10304 17382 ...

## Histogram of total of steps per day, with NA's
qplot(steps, data = totalStepsPerDay, geom = "histogram",binwidth = 500,xlab = "Total # of Daily Steps", ylab = "Frequency of Times Per Day", y = ..density.., fill = I("white"), colour = I("black")) + stat_density(geom = "line")

## Calculate mean daily number of steps
mean(totalStepsPerDay$steps)
##[1] 10766.19
## Calculate median daily number of steps
median(totalStepsPerDay$steps)
##[1] 10765

##What is the average daily activity pattern?
##Break down average number of steps over 5 minute intervals during measured period (24 hours)
##mean steps over a list of grouping elements (which is the activity dataset interval) coerced to factors with BY
stepsPerInterval <- aggregate(activityDataSet$steps,by = list(interval = activityDataSet$interval),FUN=mean, na.rm=TRUE)

##> str(stepsPerInterval)
##'data.frame':	288 obs. of  2 variables:
##  $ interval: int  0 5 10 15 20 25 30 35 40 45 ...
##  $ x       : num  1.717 0.3396 0.1321 0.1509 0.0755 ...

colnames(stepsPerInterval) <- c("interval", "steps")
ggplot(stepsPerInterval, aes(x=interval, y=steps)) + geom_line(color=I("black"), size=1) + labs(title="Daily Activity Pattern", x="5 minute intervals", y="Number of steps counted")

##Whic 5 minute interval, on average across all days in the dataset contains the nax number of steps
max(stepsPerInterval$steps)
##[1] 206.1698 This is our maximum number os steps

which.max(stepsPerInterval$steps)
##[1] 104
##This gives us the 104th record which is:
##104      835 206.1698113, giving us the interval at the 8.35 hour mark

##Imputing missing values
##=======================

##Note that there are a number of days/intervals where there are missing values (coded as NA). 
##The presence of missing days may introduce bias into some calculations or summaries of the data.

##calculate total number of missing values in the dataset
missingNaVals <- sum(is.na(activityDataSet$steps))
## This gives us 
##[1] 2304

##Devise a strategy for filling in all of the missing values in the dataset. 
##The strategy does not need to be sophisticated. For example, you could use the mean/median for that day, or the mean for that 5-minute interval, etc.

## Function that calculates mean steps for a each interval:
getMeanStepsPerInterval <- function(interval){
  stepsPerInterval[stepsPerInterval$interval==interval,"steps"]}

##make a new dataset with the NA's filled in
##============================================
activityDataSetFilled <- activityDataSet ##copy our original dataset 
## Filling the missing values with the mean for that 5-minute interval

##keep a count of how many rows we looped thorugh in our dataset. Loop through each row of the dataset until we've gone through all rows (nrow)
##whereever we find our variable steps has an NA value (is.na) and if this is the case, then we call our getMeanStepsPerInterval
##function passing in the particular interval number, and then pulling out the mean value via stepsPerInterval for the given interval
rowcount = 0 
for (i in 1:nrow(activityDataSetFilled)) { 
       if (is.na(activityDataSetFilled[i,"steps"])) {
             activityDataSetFilled[i,"steps"] <- getMeanStepsPerInterval(activityDataSetFilled[i,"interval"])
             rowcount = rowcount + 1
         }
  }
##when we run rowcount the first time it gives us:
##> rowcount
##[1] 2304
##which indicates that we looped through 2304 rows
##And if we run it again it then displays:
##> rowcount
##[1] 0
##indicating there are no further NA entries to fill in

## Histogram of total of steps per day, with NA's filled with mean values

totalStepsPerDayFilled <- aggregate(steps ~ date, activityDataSetFilled, sum)
totalStepsPerDayFilled <- data.frame(totalStepsPerDayFilled) ##convert to data frame for grpahing package

qplot(steps, data = totalStepsPerDayFilled, geom = "histogram",binwidth = 500,xlab = "Total # of Daily Steps", ylab = "Frequency of Times Per Day", y = ..density.., fill = I("white"), colour = I("black")) + stat_density(geom = "line")

##Calculate and report the mean and median total number of steps taken per day
mean(totalStepsPerDayFilled$steps)
##[1] 10766.19
median(totalStepsPerDayFilled$steps)
##[1] 10766.19
##Do these values differ from the first part of the assignment?
## The mean is the same, but the median increased to the same as the mean value. You can also see the with a desnity plot, the curve is steeper and 
##moves more towards the middle. Filling in the values with mean entries, pushes the median towards the mean.

##Are there differences in activity patterns between weekdays and weekends?
##=========================================================================
activityDataSetFilled2 <- activityDataSetFilled

##create a vector of weekdays, this way we can create a new factor variable with 2 levels, weekend and weekday - for the given date.
weekdays1 <- c('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')
##Use `%in%` and `weekdays` to create a logical vector

activityDataSetFilled2$wDay <- c('weekend', 'weekday')[(weekdays(activityDataSetFilled2$date) %in% weekdays1)+1L]
##head(activityDataSetFilled2)
##steps       date interval    wDay
##1 1.7169811 2012-10-01        0 weekday
##2 0.3396226 2012-10-01        5 weekday

##Finally, make panel plot showing time series of 5-minute interval and average number of steps takes, weekend versus weekdays.

sInt = aggregate(steps ~ interval + wDay, activityDataSetFilled2, mean)
xyplot(steps ~ interval | factor(wDay), data = sInt, aspect = 1/2,  type = "l")

