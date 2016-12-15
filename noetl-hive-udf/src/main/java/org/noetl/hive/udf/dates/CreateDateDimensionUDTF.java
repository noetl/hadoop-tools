package org.noetl.hive.udf.dates;

import java.util.ArrayList;

import org.apache.hadoop.hive.ql.exec.Description;
import org.apache.hadoop.hive.ql.exec.UDFArgumentException;
import org.apache.hadoop.hive.ql.metadata.HiveException;
import org.apache.hadoop.hive.ql.udf.generic.GenericUDTF;
import org.apache.hadoop.hive.serde2.objectinspector.ObjectInspector;
import org.apache.hadoop.hive.serde2.objectinspector.ObjectInspectorFactory;
import org.apache.hadoop.hive.serde2.objectinspector.ObjectInspectorUtils;
import org.apache.hadoop.hive.serde2.objectinspector.StructObjectInspector;
import org.apache.hadoop.hive.serde2.objectinspector.primitive.PrimitiveObjectInspectorFactory;
import org.apache.hadoop.hive.serde2.objectinspector.primitive.StringObjectInspector;
import org.joda.time.LocalDate;
import org.joda.time.format.DateTimeParser;
import org.joda.time.format.DateTimeFormat;
import org.joda.time.format.DateTimeFormatter;
import org.joda.time.format.DateTimeFormatterBuilder;


/**
 * CreateDateDimension is a UDTF for generating date dimension table from start date to end_date,
 * inclusively.
 *..
 * use hivedb;
 * add jar hdfs:///udf/noetl-hive-udf.jar;
 * CREATE TEMPORARY FUNCTION date_dim AS 'org.noetl.hive.udf.dates.CreateDateDimensionUDTF';
 *
 *  drop table if exists date_dim;
 * create table if not exists date_dim stored as orc as
 * select
 * dt.Date as date_id,
 * dt.Year as year_of_date,
 * dt.YearQarter as year_qarter,
 * dt.YearMonth as year_month,
 * dt.MonthYear as month_year,
 * dt.QuartOfYear as quarter_of_year,
 * dt.MonthName as month_name,
 * dt.MonthOfYear as month_of_year,
 * dt.WeekOfYear as week_of_year,
 * dt.DayOfYear as day_of_year,
 * dt.DayOfMonth as date_of_month,
 * dt.DayOfWeek as day_of_week
 *       from dual lateral view
 *        date_dim('2000-01-01','2020-01-01','Date,YearQarter,YearMonth,MonthYear,QuartOfYear,MonthOfYear,WeekOfYear,MonthName,Year,DayOfMonth,DayOfYear,DayOfWeek') dt
 *           as Date,YearQarter,YearMonth,MonthYear,QuartOfYear,MonthOfYear,WeekOfYear,MonthName,Year,DayOfMonth,DayOfYear,DayOfWeek;
 *
 * ======================DATE FORMAT==========================
 *  Symbol  Meaning                      Presentation  Examples
 *  ------  -------                      ------------  -------
 *  G       era                          text          AD
 *  C       century of era (>=0)         number        20
 *  Y       year of era (>=0)            year          1996
 *
 *  x       weekyear                     year          1996
 *  w       week of weekyear             number        27
 *  e       day of week                  number        2
 *  E       day of week                  text          Tuesday; Tue
 *
 *  y       year                         year          1996
 *  D       day of year                  number        189
 *  M       month of year                month         July; Jul; 07
 *  d       day of month                 number        10
 *
 *  a       halfday of day               text          PM
 *  K       hour of halfday (0~11)       number        0
 *  h       clockhour of halfday (1~12)  number        12
 *
 *  H       hour of day (0~23)           number        0
 *  k       clockhour of day (1~24)      number        24
 *  m       minute of hour               number        30
 *  s       second of minute             number        55
 *  S       fraction of second           number        978
 *
 *  z       time zone                    text          Pacific Standard Time; PST
 *  Z       time zone offset/id          zone          -0800; -08:00; America/Los_Angeles
 *
 *
 *
 */
@Description(name = "date_join", value = "_FUNC_(date1, date2,column list<Date,YearQarter,YearMonth,MonthYear,QuartOfYear,MonthOfYear,WeekOfYear,MonthName,Year,DayOfMonth,DayOfYear,DayOfWeek,index>) - generates a date dimension recordset"
        + " incremented by given period like days or months")
public class CreateDateDimensionUDTF extends GenericUDTF {
    //private DateTimeFormatter YYYYMMDD = DateTimeFormat.forPattern("yyyy-MMM-dd");
    private StringObjectInspector startInspector = null;
    private StringObjectInspector endInspector = null;
    private Object[] forwardListObj = null;
    private String start = "2010-01-01";
    private String end = "2010-01-01";
    private String format = "yyyy-MM-dd";
    private int incr = 1;
    private String stringOI[];
    private DateTimeFormatter YYYYMMDD =
            new DateTimeFormatterBuilder()
                    .append(null, new DateTimeParser[]{
                            DateTimeFormat.forPattern("dd/MM/yyyy").getParser(),
                            DateTimeFormat.forPattern("yyyy/MM/dd").getParser(),
                            DateTimeFormat.forPattern("yyyy-MM-dd").getParser()})
                    .toFormatter();

    @Override
    public StructObjectInspector initialize(ObjectInspector[]  argOIs)
            throws UDFArgumentException {

        if (argOIs.length != 3) {
            throw new UDFArgumentException(
                    "Date_dim takes <startdate>, <enddate>, <list of dimensions>");
        }
        if (!(argOIs[0] instanceof StringObjectInspector))
            throw new UDFArgumentException(
                    "Date_dim takes <startdate> as string");
        else
            startInspector = (StringObjectInspector) argOIs[0];
        if (!(argOIs[1] instanceof StringObjectInspector))
            throw new UDFArgumentException(
                    "Date_dim takes <enddate> as string");
        else
            endInspector = (StringObjectInspector) argOIs[1];
        if (!(argOIs[2] instanceof StringObjectInspector))
            throw new UDFArgumentException(
                    "Date_dim takes <list of dimensions> as a comma separated list");
        else {
            stringOI = ObjectInspectorUtils.getWritableConstantValue((StringObjectInspector) argOIs[2]).toString().split(",");

            ArrayList<String> fieldNames = new ArrayList<String>();
            ArrayList<ObjectInspector> fieldOIs = new ArrayList<ObjectInspector>();
            for ( int i = 0; i <= stringOI.length - 1; i++) {
                fieldNames.add(stringOI[i].trim());
                if (stringOI[i].trim().equals("index")) {
                    fieldOIs.add(PrimitiveObjectInspectorFactory.javaIntObjectInspector);
                } else {
                    fieldOIs.add(PrimitiveObjectInspectorFactory.javaStringObjectInspector);
                }
            }

            forwardListObj = new Object[stringOI.length];
            return ObjectInspectorFactory.getStandardStructObjectInspector(
                    fieldNames, fieldOIs);
        }
    }


    @Override
    public void process(Object[] args) throws HiveException {

        switch (args.length) {
            case 3:
                incr = 1;
            case 2:
                start = startInspector.getPrimitiveJavaObject(args[0]);
                end = endInspector.getPrimitiveJavaObject(args[1]);
                break;
        }

        try {
            LocalDate startDt = YYYYMMDD.parseDateTime(start).toLocalDate();
            LocalDate endDt = YYYYMMDD.parseDateTime(end).toLocalDate();
            int i = 0;

            for (LocalDate dt = startDt; dt.isBefore(endDt) || dt.isEqual(endDt);
                 dt = dt.plusDays(incr) , i++) {
                for ( int j = 0; j <= stringOI.length - 1; j++) {
                    switch (stringOI[j].trim()) {
                        case "Year":
                            forwardListObj[j] = TranslateDates.getYear(dt);
                            break;
                        case "YearQarter":
                            forwardListObj[j] = TranslateDates.getYear(dt) +"Q" + TranslateDates.getQuartOfYear(dt);
                            break;
                        case "YearMonth":
                            forwardListObj[j] = TranslateDates.getLocDate(dt,"yyyyMM");
                            break;
                        case "MonthYear":
                            forwardListObj[j] = TranslateDates.getLocDate(dt,"MMM-yyyy");
                            break;
                        case "DayOfMonth":
                            forwardListObj[j] = TranslateDates.getDateOfMonth(dt);
                            break;
                        case "MonthName":
                            forwardListObj[j] = TranslateDates.getLocDate(dt,"MMMM");
                            break;
                        case "QuartOfYear":
                            forwardListObj[j] = "Q" + TranslateDates.getQuartOfYear(dt);
                            break;
                        case "MonthOfYear":
                            forwardListObj[j] = TranslateDates.getMonthOfYear(dt);
                            break;
                        case "WeekOfYear":
                            forwardListObj[j] = TranslateDates.getWeekOfYear(dt);
                            break;
                        case "DayOfYear":
                            forwardListObj[j] = TranslateDates.getDayOfYear(dt);
                            break;
                        case "DayOfWeek":
                            forwardListObj[j] = TranslateDates.getDayOfWeek(dt);
                            break;
                        case "index":
                            forwardListObj[j] = new Integer(i);
                            break;
                        default:
                            forwardListObj[j] = TranslateDates.getLocDate(dt,format);
                            break;
                    } // switch
                } // for j
                forward(forwardListObj);
            } // for dt

        } catch (IllegalArgumentException badFormat) {
            throw new HiveException("Unable to parse dates; start = " + start
                    + " ; end = " + end);
        }
    }
    @Override
    public void close() throws HiveException {
    }
}
