import org.apache.spark.SparkContext
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._

object HW4Pipeline {
  def run(spark: SparkSession, sc: SparkContext): Unit = {
    require(sc.master == "yarn", s"Expected YARN, got ${sc.master}")
    println(s"HW4 YARN application: ${sc.applicationId}")

    val input = "hdfs://team-17-nn:9000/user/hive/warehouse/hw3_events"
    val output = "hdfs://team-17-nn:9000/user/hive/warehouse/hw4_events_agg"
    val raw = spark.read.option("header", "false").csv(input)
    val events = raw.select(
      col("_c0").cast("int").as("id"),
      col("_c1").cast("int").as("user_id"),
      col("_c2").as("event_type"),
      col("_c3").cast("double").as("value"),
      col("dt").cast("date").as("dt")
    )
    require(events.count() == 6L, "Expected six HW3 source records")
    require(events.filter(col("id").isNull || col("user_id").isNull || col("value").isNull || col("dt").isNull).count() == 0L,
      "Source contains null or invalid typed values")

    // We validated every id, so we can safely declare it non-nullable.
    val strictSchema = StructType(events.schema.fields.map(f => if (f.name == "id") f.copy(nullable = false) else f))
    val eventsNN = spark.createDataFrame(events.rdd, strictSchema)
    eventsNN.printSchema()

    val aggregated = eventsNN.filter(col("value").isNotNull)
      .groupBy("dt")
      .agg(count("*").as("event_count"),
           round(sum("value"), 2).as("total_value"),
           round(avg("value"), 2).as("avg_value"))
    val result = aggregated.withColumn("dt", col("dt").cast("string"))
    val expected = Map(
      "2026-10-20" -> (2L, 3.5, 1.75),
      "2026-10-21" -> (2L, 18.5, 9.25),
      "2026-10-22" -> (2L, 21.5, 10.75)
    )
    val actual = result.collect().map { r =>
      r.getAs[String]("dt") -> (r.getAs[Long]("event_count"), r.getAs[Double]("total_value"), r.getAs[Double]("avg_value"))
    }.toMap
    require(actual == expected, s"Unexpected aggregation: $actual")

    result.orderBy("dt").show(false)
    result.write.mode("overwrite").partitionBy("dt").parquet(output)

    val saved = spark.read.parquet(output)
    require(saved.count() == 3L, "Expected three aggregate rows")
    val dates = saved.select("dt").collect().map(_.get(0).toString).toSet
    require(dates == expected.keySet, s"Unexpected Parquet partitions: $dates")
    saved.orderBy("dt").show(false)
  }
}

try {
  HW4Pipeline.run(spark, sc)
  println("HW4_SPARK_OK")
  sc.stop()
  System.exit(0)
} catch {
  case t: Throwable =>
    t.printStackTrace()
    System.exit(1)
}
