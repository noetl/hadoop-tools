package org.noetl.hive.udf.dates;


import org.noetl.hive.udf.dates.TranslateDates;

import java.text.ParseException;
import java.util.regex.Pattern;

import org.apache.hadoop.hive.ql.exec.Description;
import org.apache.hadoop.hive.ql.exec.UDF;
import org.joda.time.LocalDate;


/**
 * CREATE TEMPORARY  FUNCTION last_date_month AS 'org.noetl.hive.udf.dates.LastDateOfTheMonthUDF';
 * select date_fomat('200802','YYYYMM') from dual;
 */
@Description(name = "last_date_month",
        value = "_FUNC_(YYYY-MM-DD) - returns the last date of the month for the given DATE STRING. In case of failure returns \"0001-01-01\" \n")


public class LastDateOfTheMonthUDF extends UDF {


    static final Pattern PATTERN = Pattern.compile("^(-?0|-?[1-9]\\d*)(\\.\\d+)?(E\\d+)?$");

    public String evaluate(String date, String format) throws ParseException {
        LocalDate parsedDate;
        try {
            if (format.equals("yyyyMM")) {
                date = date + "01";
                format = format + "dd";
            } else if (format.equals("yyyy-MM"))  {
                date = date + "-01";
                format = format + "-dd";
            }

            parsedDate = TranslateDates.setLocDate(date,format);
        } catch(NullPointerException | ParseException nex) {
            try {
                parsedDate = TranslateDates.setLocDate(TranslateDates.dateFormat("0001-01-01",format)) ;
            } catch (NullPointerException | ParseException ex2) {
                parsedDate = TranslateDates.setLocDate("0001-01-01");
            }
        }
        return TranslateDates.getMonthLastLocDate(parsedDate);
    }

    public String evaluate(String date, String srcformat, String dstformat) throws ParseException {
        LocalDate parsedDate;
        try {
            if (srcformat.equals("yyyyMM")) {
                date = date + "01";
                srcformat = srcformat + "dd";
            } else if (srcformat.equals("yyyy-MM"))  {
                date = date + "-01";
                srcformat = srcformat + "-dd";
            }
            parsedDate = TranslateDates.setLocDate(date,srcformat);
        } catch(NullPointerException | ParseException nex) {
            try {
                parsedDate = TranslateDates.setLocDate(TranslateDates.dateFormat(date,dstformat)) ;
            } catch (NullPointerException | ParseException ex2) {
                parsedDate = TranslateDates.setLocDate(TranslateDates.dateFormat("0001-01-01",dstformat)) ;
            }
        }
        return TranslateDates.dateFormat(TranslateDates.getMonthLastLocDate(parsedDate),dstformat);
    }


    public static boolean isNumeric(String value) {

        return value != null && PATTERN.matcher(value).matches();

    }
} // YearMonth

