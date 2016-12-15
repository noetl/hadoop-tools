#Hive UDFs

##Compile

mvn compile

##Test

mvn test

##Build

mvn assembly:single

##Package

mvn package

##Run

%> hive
hive> ADD JAR /udfs/noetl-hive-udf.jar;
hive> create temporary function DateDimUDTF as 'org.noetl.udf.dates.DateDimensionUDTF';
hive> select DateDimUDTF(...dates) from test;
