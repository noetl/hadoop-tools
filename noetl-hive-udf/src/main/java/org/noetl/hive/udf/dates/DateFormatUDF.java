package org.noetl.hive.udf.dates;


import org.noetl.hive.udf.dates.TranslateDates;
import java.text.ParseException;
import java.util.regex.Pattern;
import org.apache.hadoop.hive.ql.exec.Description;
import org.apache.hadoop.hive.ql.exec.UDF;


/**
 * CREATE TEMPORARY FUNCTION date_format AS 'org.noetl.hive.udf.dates.DateFormatUDF';
 * args[0] the date
 * args[1] the date format or the source date format
 * args[2] the destination date format
 * select date_fomat('2008-02-01','YYYY-MM') from dual;
 */
@Description(name = "date_format",
        value = "_FUNC_(YYYY-MM-DD) - Converts given DATE  STRING to given format e.g. DD-MON-YY. In case of failure returns \"0001-01-01\" \n")


public class DateFormatUDF extends UDF {


    static final Pattern PATTERN = Pattern.compile("^(-?0|-?[1-9]\\d*)(\\.\\d+)?(E\\d+)?$");

    public String evaluate(String date, String format) {
        String parsedDate;
        try {
            parsedDate = TranslateDates.dateFormat(date,format) ;
        } catch(NullPointerException | ParseException nex) {
            try {
                parsedDate = TranslateDates.dateFormat("0001-01-01",format) ;
            } catch (ParseException ex2) {
                parsedDate = "0001-01-01";
            }
        }
        return parsedDate;
    }

    public String evaluate(String date, String srcformat, String dstformat) throws ParseException {
        String parsedDate;
        try {
            return TranslateDates.dateFormat(date,srcformat, dstformat) ;
        } catch(NullPointerException | ParseException nex) {
            try {
                parsedDate = TranslateDates.dateFormat(date,dstformat) ;
            } catch (NullPointerException | ParseException ex2) {
                parsedDate = TranslateDates.dateFormat("0001-01-01",dstformat) ;
            }
        }
        return parsedDate;
    }


    public static boolean isNumeric(String value) {

        return value != null && PATTERN.matcher(value).matches();

    }
} // YearMonth

