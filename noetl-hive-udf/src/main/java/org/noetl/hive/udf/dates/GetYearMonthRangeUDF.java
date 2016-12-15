package org.noetl.hive.udf.dates;

import org.noetl.hive.udf.dates.TranslateDates;

import java.text.ParseException;

import org.apache.hadoop.hive.ql.exec.Description;
import org.apache.hadoop.hive.ql.exec.UDF;
import org.joda.time.LocalDate;


/**
 * CREATE TEMPORARY  FUNCTION get_ym_range AS 'org.noetl.hive.udf.dates.GetYearMonthRangeUDF';
 * select get_ym_range('201510','yyyyMM',6) from dual;
 */
@Description(name = "get_ym_range",
        value = "_FUNC_('201511','yyyyMM',5)- returns the range of the past months from  the given DATE STRING. In case of failure returns \"\" \n")


public class GetYearMonthRangeUDF extends UDF {

    public String evaluate(String date, String format, int range) throws ParseException {
        LocalDate parsedDate;
        String parsed_Date;
        String s;
        String result_format = "yyyyMM";
        String src_format=format;
        String src_date=date;


        StringBuilder sb = new StringBuilder();
        //sb.append("\"");
        try {
            if (format.equals("yyyyMM")) {
                src_date = date + "01";
                src_format = format + "dd";
            } else if (format.equals("yyyy-MM"))  {
                src_date = date + "-01";
                src_format = format + "-dd";
            }
            parsed_Date = TranslateDates.dateFormat(src_date,src_format,"yyyy-MM-dd");
            parsedDate = TranslateDates.setLocDate(parsed_Date);
            if (!parsed_Date.equals("0001-01-01")){
                //System.out.println("Date " +TranslateDates.dateFormat(src_date,src_format,"yyyy-MM-dd")+ " is not correct");
                for(int i=range-1; i>=0; i--){
                    s=TranslateDates.dateFormat(TranslateDates.addMonths(parsedDate,-i),"yyyy-MM-dd",result_format);
                    sb.append(s);
                    if (i>0){sb.append(',');}
                }
            }
        } catch(NullPointerException | ParseException nex) {
            System.out.println("Date Format=" +format+ " is not correct");
        }
        //sb.append("\"");
        return sb.toString();
    }

} // YearMonth

