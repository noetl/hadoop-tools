package org.noetl.hive.udf.dates;

import java.util.ArrayList;

import org.apache.hadoop.hive.ql.exec.Description;
import org.apache.hadoop.hive.ql.exec.UDFArgumentException;
import org.apache.hadoop.hive.ql.metadata.HiveException;
import org.apache.hadoop.hive.ql.udf.generic.GenericUDTF;
import org.apache.hadoop.hive.serde2.objectinspector.ObjectInspector;
import org.apache.hadoop.hive.serde2.objectinspector.ObjectInspectorFactory;
import org.apache.hadoop.hive.serde2.objectinspector.StructObjectInspector;
import org.apache.hadoop.hive.serde2.objectinspector.primitive.IntObjectInspector;
import org.apache.hadoop.hive.serde2.objectinspector.primitive.PrimitiveObjectInspectorFactory;
import org.apache.hadoop.hive.serde2.objectinspector.primitive.StringObjectInspector;
import org.joda.time.LocalDate;
import org.joda.time.format.DateTimeFormat;
import org.joda.time.format.DateTimeFormatter;

/**
 * DateRange is a UDTF for generating days from start date to end_date,
 * inclusively.
 *
 * This might be useful in cases where one needed to have a row for every day in
 * the range ...
 * add jar hdfs:///udf/noetl-hive-udf.jar;
 * CREATE TEMPORARY FUNCTION date_fomat AS 'org.noetl.hive.udf.dates.DateFormatUDF';
 * select rnd.index,rnd.FormatedDate
 *   from dual lateral view date_join('2000-02-01','2000-03-01',1,'days','yyyy-MM-dd') rnd as FormatedDate,index;

 *
 *
 */
@Description(name = "date_join", value = "_FUNC_(date1, date2,increment,months,yyyy-dd) - generates a list of formated string output sorted by given date range"
        + " incremented by given period like days or months")
public class JoinDatesUDTF extends GenericUDTF {
    private static DateTimeFormatter defaultDateFormat = DateTimeFormat
            .forPattern("yyyy-MM-dd");
    private StringObjectInspector startInspector = null;
    private StringObjectInspector endInspector = null;
    private IntObjectInspector incrInspector = null;
    private StringObjectInspector incrPeriod = null;
    private StringObjectInspector dateFormat = null;
    private Object[] forwardListObj = null;
    private String start = null;
    private String end = null;
    private String format = "YYYY-MM-DD";
    private String period = "days";
    private int incr = 1;

    @Override
    public StructObjectInspector initialize(ObjectInspector[] argOIs)
            throws UDFArgumentException {
        if (argOIs.length != 5) {
            throw new UDFArgumentException(
                    "Date_join takes <startdate>, <enddate>, <increment>, <increment period>,<output format>");
        }
        if (!(argOIs[0] instanceof StringObjectInspector))
            throw new UDFArgumentException(
                    "Date_join takes <startdate> as string");
        else
            startInspector = (StringObjectInspector) argOIs[0];
        if (!(argOIs[1] instanceof StringObjectInspector))
            throw new UDFArgumentException(
                    "Date_join takes <enddate> as string");
        else
            endInspector = (StringObjectInspector) argOIs[1];
        if (!(argOIs[2] instanceof IntObjectInspector))
            throw new UDFArgumentException(
                    "Date_join takes <increment> as int");
        else
            incrInspector = (IntObjectInspector) argOIs[2];
        if (!(argOIs[3] instanceof StringObjectInspector))
            throw new UDFArgumentException(
                    "Date_join takes <period of increment> as string");
        else
            incrPeriod = (StringObjectInspector) argOIs[3];
        if (!(argOIs[4] instanceof StringObjectInspector))
            throw new UDFArgumentException(
                    "Date_join takes <output format> as string");
        else
            dateFormat = (StringObjectInspector) argOIs[4];

        ArrayList<String> fieldNames = new ArrayList<String>();
        fieldNames.add("FormatedDate");
        fieldNames.add("index");
        ArrayList<ObjectInspector> fieldOIs = new ArrayList<ObjectInspector>();
        fieldOIs.add(PrimitiveObjectInspectorFactory.javaStringObjectInspector);
        fieldOIs.add(PrimitiveObjectInspectorFactory.javaIntObjectInspector);

        forwardListObj = new Object[2];
        return ObjectInspectorFactory.getStandardStructObjectInspector(
                fieldNames, fieldOIs);
    }


    @Override
    public void process(Object[] args) throws HiveException {

        switch (args.length) {
            case 5:
                format = dateFormat.getPrimitiveJavaObject(args[4]).isEmpty() ? "YYYY-MM-DD" : dateFormat.getPrimitiveJavaObject(args[4]) ;
            case 4:
                period = incrPeriod.getPrimitiveJavaObject(args[3]).isEmpty()  ? "days" : incrPeriod.getPrimitiveJavaObject(args[3]);
            case 3:
                incr = incrInspector.get(args[2])<1 ? 1 : incrInspector.get(args[2]);
            case 2:
                start = startInspector.getPrimitiveJavaObject(args[0]);
                end = endInspector.getPrimitiveJavaObject(args[1]);
                break;
        }
        try {

            LocalDate startDt = defaultDateFormat.parseDateTime(start).toLocalDate();
            LocalDate endDt = defaultDateFormat.parseDateTime(end).toLocalDate();
            int i = 0;

            for (LocalDate dt = startDt; dt.isBefore(endDt) || dt.isEqual(endDt);
                 dt = period.equalsIgnoreCase("days") ? dt.plusDays(incr) : dt.plusMonths(incr) , i++) {
                forwardListObj[0] = TranslateDates.getLocDate(dt,format);
                forwardListObj[1] = new Integer(i);
                forward(forwardListObj);
            }

        } catch (IllegalArgumentException badFormat) {
            throw new HiveException("Unable to parse dates; start = " + start
                    + " ; end = " + end);
        }
    }
    @Override
    public void close() throws HiveException {
    }
}
