package org.apache.hadoop.mapred;

import java.io.IOException;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.mapred.FileOutputCommitter;
import org.apache.hadoop.mapred.FileOutputFormat;
import org.apache.hadoop.mapred.JobConf;
import org.apache.hadoop.mapred.JobContext;
import org.apache.hadoop.mapred.TaskAttemptContext;

/**
 * OutputCommitter suitable for S3 workloads. Unlike the usual FileOutputCommitter, which
 * writes files to a _temporary/ directory before renaming them to their final location, this
 * simply writes directly to the final location.
 *
 * The FileOutputCommitter is required for HDFS + speculation, which allows only one writer at
 * a time for a file (so two people racing to write the same file would not work). However, S3
 * supports multiple writers outputting to the same file, where visibility is guaranteed to be
 * atomic. This is a monotonic operation: all writers should be writing the same data, so which
 * one wins is immaterial.
 *
 * Put jar file with the class to /usr/lib/hadoop/client, /usr/lib/spark/lib
 * Add the following settings to mapred-site.xml
 * <property>
 *   <name>mapred.output.direct.EmrFileSystem</name>
 *   <value>true</value>
 * </property>
 * <property>
 *   <name>mapred.output.direct.NativeS3FileSystem</name>
 *   <value>true</value>
 * </property>
 * <property>
 *   <name>mapred.output.committer.class</name>
 *   <value>org.apache.hadoop.mapred.DirectFileOutputCommitter</value>
 * </property>
 */
public class DirectFileOutputCommitter extends FileOutputCommitter {
  private static final Log LOG = LogFactory.getLog(DirectFileOutputCommitter.class);

  public DirectFileOutputCommitter() {
  }

  public void setupJob(JobContext context) throws IOException {
    if(this.isDirectWrite(context)) {
      LOG.info("Nothing to setup since the outputs are written directly.");
    } else {
      super.setupJob(context);
    }

  }

  public void cleanupJob(JobContext context) throws IOException {
    if(this.isDirectWrite(context)) {
      LOG.info("Nothing to clean up since no temporary files were written.");
    } else {
      super.cleanupJob(context);
    }

  }

  public void setupTask(TaskAttemptContext context) throws IOException {
    if(!this.isDirectWrite(context)) {
      super.setupTask(context);
    }

  }

  public void commitTask(TaskAttemptContext context) throws IOException {
    if(this.isDirectWrite(context)) {
      LOG.info("Commit should not be called since this task doesnt have any commitable files. Also needsTaskCommit returns false");
    } else {
      super.commitTask(context);
    }

  }

  public void abortTask(TaskAttemptContext context) throws IOException {
    if(this.isDirectWrite(context)) {
      LOG.info("Nothing to clean up on abort since there are no temporary files written");
    } else {
      super.abortTask(context);
    }

  }

  public boolean needsTaskCommit(TaskAttemptContext context) throws IOException {
    return this.isDirectWrite(context)?false:super.needsTaskCommit(context);
  }

  public Path getWorkPath(TaskAttemptContext taskContext, Path basePath) throws IOException {
    return this.isDirectWrite(taskContext)?FileOutputFormat.getOutputPath(taskContext.getJobConf()):super.getWorkPath(taskContext, basePath);
  }

  private boolean isDirectWrite(TaskAttemptContext c) throws IOException {
    return this.isDirectWrite(c.getJobConf(), c.getConfiguration());
  }

  private boolean isDirectWrite(JobContext jc) throws IOException {
    return this.isDirectWrite(jc.getJobConf(), jc.getConfiguration());
  }

  private boolean isDirectWrite(JobConf conf, Configuration config) throws IOException {
    Path p = FileOutputFormat.getOutputPath(conf);
    if(p == null) {
      return false;
    } else {
      FileSystem fs = p.getFileSystem(conf);
      return config.getBoolean("mapred.output.direct." + fs.getClass().getSimpleName(), false);
    }
  }
}
