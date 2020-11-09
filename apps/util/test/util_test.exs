defmodule UtilTest do
  use ExUnit.Case, async: true
  use Quixir
  import Util
  import ExUnit.CaptureLog, only: [capture_log: 1]
  doctest Util
  doctest Util.Polygon

  describe "now/1" do
    test "handles ambiguous UTC times by returning the earlier time" do
      for {time, expected} <- [
            {~N[2016-11-06T05:00:00], "2016-11-06T01:00:00-04:00"},
            {~N[2016-11-06T06:00:00], "2016-11-06T02:00:00-04:00"},
            {~N[2016-11-06T07:00:00], "2016-11-06T02:00:00-05:00"}
          ] do
        utc_fn = fn "America/New_York" -> Timex.set(time, timezone: "UTC") end
        assert utc_fn |> now() |> Timex.format("{ISO:Extended}") == {:ok, expected}
      end
    end
  end

  describe "to_local_time/1" do
    test "handles NaiveDateTime" do
      assert %DateTime{day: 02, hour: 0, zone_abbr: "EST"} =
               Util.to_local_time(~N[2016-01-02T05:00:00])
    end

    test "handles NaiveDateTime in EST -> EDT transition" do
      assert %DateTime{month: 3, day: 11, hour: 1, zone_abbr: "EST"} =
               Util.to_local_time(~N[2018-03-11T06:00:00])

      assert %DateTime{month: 3, day: 11, hour: 3, zone_abbr: "EDT"} =
               Util.to_local_time(~N[2018-03-11T07:00:00])
    end

    test "handles NaiveDateTime in EDT -> EST transition" do
      assert %DateTime{month: 11, day: 4, hour: 1, zone_abbr: "EDT"} =
               Util.to_local_time(~N[2018-11-04T05:00:00])

      assert %DateTime{month: 11, day: 4, hour: 2, zone_abbr: "EDT"} =
               Util.to_local_time(~N[2018-11-04T06:00:00])

      assert %DateTime{month: 11, day: 4, hour: 2, zone_abbr: "EST"} =
               Util.to_local_time(~N[2018-11-04T07:00:00])
    end

    test "handles DateTime in UTC timezone" do
      assert %DateTime{day: 02, hour: 0} =
               ~N[2016-01-02T05:00:00]
               |> DateTime.from_naive!("Etc/UTC")
               |> Util.to_local_time()
    end

    test "handles Timex.AmbiguousDateTime.t" do
      before_date = Util.to_local_time(~N[2018-11-04T05:00:00])
      after_date = Util.to_local_time(~N[2018-11-04T06:00:00])

      assert before_date ==
               Util.to_local_time(%Timex.AmbiguousDateTime{after: after_date, before: before_date})
    end
  end

  describe "service_date/0" do
    test "returns the service date for the current time" do
      assert service_date() == service_date(now())
    end
  end

  describe "service_date/1 for NaiveDateTime" do
    test "returns the service date" do
      yesterday = ~D[2016-01-01]
      today = ~D[2016-01-02]

      midnight = ~N[2016-01-02T05:00:00]
      assert %DateTime{day: 02, hour: 0} = Util.to_local_time(midnight)
      assert Util.service_date(midnight) == yesterday

      one_am = ~N[2016-01-02T06:00:00]
      assert %DateTime{day: 02, hour: 1} = Util.to_local_time(one_am)
      assert Util.service_date(one_am) == yesterday

      two_am = ~N[2016-01-02T07:00:00]
      assert %DateTime{day: 02, hour: 2} = Util.to_local_time(two_am)
      assert Util.service_date(two_am) == yesterday

      three_am = ~N[2016-01-02T08:00:00]
      assert %DateTime{day: 02, hour: 3} = Util.to_local_time(three_am)
      assert Util.service_date(three_am) == today

      four_am = ~N[2016-01-02T09:00:00]
      assert %DateTime{day: 02, hour: 4} = Util.to_local_time(four_am)
      assert Util.service_date(four_am) == today
    end

    test "handles EST -> EDT transition" do
      # midnight EST
      assert Util.service_date(~N[2018-03-11T05:00:00]) == ~D[2018-03-10]
      # 1am EST
      assert Util.service_date(~N[2018-03-11T06:00:00]) == ~D[2018-03-10]
      # 2am EST / 3am EDT
      assert Util.service_date(~N[2018-03-11T07:00:00]) == ~D[2018-03-11]
      # 4am EDT
      assert Util.service_date(~N[2018-03-11T08:00:00]) == ~D[2018-03-11]
    end

    test "handles EDT -> EST transition" do
      # midnight EDT
      assert Util.service_date(~N[2018-11-04T04:00:00]) == ~D[2018-11-03]
      # 1am EDT
      assert Util.service_date(~N[2018-11-04T05:00:00]) == ~D[2018-11-03]
      # 2am EDT / 1am EST
      assert Util.service_date(~N[2018-11-04T06:00:00]) == ~D[2018-11-03]
      # 2am EST
      assert Util.service_date(~N[2018-11-04T07:00:00]) == ~D[2018-11-03]
      # 3am EST
      assert Util.service_date(~N[2018-11-04T08:00:00]) == ~D[2018-11-04]
      # 4am EST
      assert Util.service_date(~N[2018-11-04T09:00:00]) == ~D[2018-11-04]
    end
  end

  describe "service_date/1 for DateTime in America/New_York timezone" do
    test "returns the service date" do
      yesterday = ~D[2016-01-01]
      today = ~D[2016-01-02]

      # 12am
      assert ~N[2016-01-02T05:00:00]
             |> Util.to_local_time()
             |> Util.service_date() == yesterday

      # 1am
      assert ~N[2016-01-02T06:00:00]
             |> Util.to_local_time()
             |> Util.service_date() == yesterday

      # 2am
      assert ~N[2016-01-02T07:00:00]
             |> Util.to_local_time()
             |> Util.service_date() == yesterday

      # 3am
      assert ~N[2016-01-02T08:00:00]
             |> Util.to_local_time()
             |> Util.service_date() == today

      # 4am
      assert ~N[2016-01-02T09:00:00]
             |> Util.to_local_time()
             |> Util.service_date() == today
    end

    test "handles EST -> EDT transition" do
      # midnight EST
      assert ~N[2018-03-11T05:00:00]
             |> Util.to_local_time()
             |> Util.service_date() == ~D[2018-03-10]

      # 1am EST
      assert ~N[2018-03-11T06:00:00]
             |> Util.to_local_time()
             |> Util.service_date() == ~D[2018-03-10]

      # 2am EST / 3am EDT
      assert ~N[2018-03-11T07:00:00]
             |> Util.to_local_time()
             |> Util.service_date() == ~D[2018-03-11]

      # 4am EDT
      assert ~N[2018-03-11T08:00:00]
             |> Util.to_local_time()
             |> Util.service_date() == ~D[2018-03-11]
    end

    test "handles EDT -> EST transition" do
      # midnight EDT
      assert ~N[2018-11-04T04:00:00]
             |> Util.to_local_time()
             |> Util.service_date() == ~D[2018-11-03]

      # 1am EDT
      assert ~N[2018-11-04T05:00:00]
             |> Util.to_local_time()
             |> Util.service_date() == ~D[2018-11-03]

      # 2am EDT / 1am EST
      assert ~N[2018-11-04T06:00:00]
             |> Util.to_local_time()
             |> Util.service_date() == ~D[2018-11-03]

      # 2am EST
      assert ~N[2018-11-04T07:00:00]
             |> Util.to_local_time()
             |> Util.service_date() == ~D[2018-11-03]

      # 3am EST
      assert ~N[2018-11-04T08:00:00]
             |> Util.to_local_time()
             |> Util.service_date() == ~D[2018-11-04]

      # 4am EST
      assert ~N[2018-11-04T09:00:00]
             |> Util.to_local_time()
             |> Util.service_date() == ~D[2018-11-04]
    end
  end

  describe "service_date/1 for DateTime in UTC timezone" do
    test "returns the service date" do
      yesterday = ~D[2016-01-01]
      today = ~D[2016-01-02]

      # 12am
      assert ~N[2016-01-02T05:00:00]
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == yesterday

      # 1am
      assert ~N[2016-01-02T06:00:00]
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == yesterday

      # 2am
      assert ~N[2016-01-02T07:00:00]
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == yesterday

      # 3am
      assert ~N[2016-01-02T08:00:00]
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == today

      # 4am
      assert ~N[2016-01-02T09:00:00]
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == today
    end

    test "handles EST -> EDT transition" do
      # midnight EST
      assert ~N[2018-03-11T05:00:00]
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == ~D[2018-03-10]

      # 1am EST
      assert ~N[2018-03-11T06:00:00]
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == ~D[2018-03-10]

      # 2am EST / 3am EDT
      assert ~N[2018-03-11T07:00:00]
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == ~D[2018-03-11]

      # 4am EDT
      assert ~N[2018-03-11T08:00:00]
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == ~D[2018-03-11]
    end

    test "handles EDT -> EST transition" do
      # midnight EDT
      assert ~N[2018-11-04T04:00:00]
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == ~D[2018-11-03]

      # 1am EDT
      assert ~N[2018-11-04T05:00:00]
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == ~D[2018-11-03]

      # 2am EDT / 1am EST
      assert ~N[2018-11-04T06:00:00]
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == ~D[2018-11-03]

      # 2am EST
      assert ~N[2018-11-04T07:00:00]
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == ~D[2018-11-03]

      # 3am EST
      assert ~N[2018-11-04T08:00:00]
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == ~D[2018-11-04]

      # 4am EST
      assert ~N[2018-11-04T09:00:00]
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == ~D[2018-11-04]
    end
  end

  describe "interleave" do
    test "interleaves lists" do
      assert Util.interleave([1, 3, 5], [2, 4, 6]) == [1, 2, 3, 4, 5, 6]
    end

    test "handles empty lists" do
      assert Util.interleave([1, 2, 3], []) == [1, 2, 3]
      assert Util.interleave([], [1, 2, 3]) == [1, 2, 3]
    end

    test "handles lists of different lengths" do
      assert Util.interleave([1, 3], [2, 4, 5, 6]) == [1, 2, 3, 4, 5, 6]
      assert Util.interleave([1, 3, 5, 6], [2, 4]) == [1, 2, 3, 4, 5, 6]
    end
  end

  describe "async_with_timeout/3" do
    test "returns the value of a task if it ends in time" do
      assert async_with_timeout([fn -> 5 end, fn -> 6 end], nil, __MODULE__, 1000) == [5, 6]
      assert async_with_timeout([fn -> 5 end, fn -> 6 end], nil, __MODULE__) == [5, 6]
    end

    test "returns results in the same order functions were passed in" do
      results = Enum.to_list(0..99)

      functions =
        Enum.map(
          results,
          &fn ->
            :timer.sleep(&1)
            &1
          end
        )

      assert async_with_timeout(functions, nil, __MODULE__) == results
    end

    test "returns the default for a task that runs too long and logs a warning" do
      log =
        capture_log(fn ->
          assert async_with_timeout(
                   [
                     fn -> 5 end,
                     fn -> :timer.sleep(60_000) end
                   ],
                   :default,
                   __MODULE__,
                   10
                 ) == [5, :default]
        end)

      assert log =~ "Async task timed out"
    end
  end

  describe "yield_or_default/4" do
    test "returns result when task does not timeout" do
      task = Task.async(fn -> :success end)
      assert yield_or_default(task, 1_000, :fail, __MODULE__) == :success
    end

    test "returns default when task times out" do
      task =
        Task.async(fn ->
          :timer.sleep(60_000)
          :async
        end)

      log =
        capture_log(fn ->
          assert yield_or_default(task, 10, :default, __MODULE__) == :default
        end)

      assert log =~ "error=async_error"
    end
  end

  describe "yield_or_default_many/2" do
    test "returns result when task does not timeout, and default when it does" do
      short_fn = fn -> :task_result end
      long_fn = fn -> :timer.sleep(1_000) end
      aborted_task = Task.async(long_fn)

      task_map = %{
        Task.async(short_fn) => {:short, :short_default},
        Task.async(long_fn) => {:long, :long_default},
        aborted_task => {:aborted, :aborted_default}
      }

      Process.unlink(aborted_task.pid)
      Process.exit(aborted_task.pid, :kill)

      log =
        capture_log(fn ->
          assert Util.yield_or_default_many(task_map, __MODULE__, 500) == %{
                   short: :task_result,
                   long: :long_default,
                   aborted: :aborted_default
                 }
        end)

      assert log =~ "Defaulting to: :long_default"
      assert log =~ "exited for reason: :killed"
      refute log =~ "Defaulting to: :short_default"
    end
  end

  test "config/2 returns config values" do
    Application.put_env(:util, :config_test, {:system, "CONFIG_TEST", "default"})
    assert Util.config(:util, :config_test) == "default"
    System.put_env("CONFIG_TEST", "env")
    assert Util.config(:util, :config_test) == "env"
    System.delete_env("CONFIG_TEST")
    Application.delete_env(:util, :config_test)
  end

  test "config/2 doesn't raise if config isn't found" do
    assert Util.config(:util, :config_test) == nil
  end

  test "config/3 returns nested config values" do
    Application.put_env(:util, :config_test, nested: {:system, "CONFIG_TEST", "default"})
    assert Util.config(:util, :config_test, :nested) == "default"
    System.put_env("CONFIG_TEST", "env")
    assert Util.config(:util, :config_test, :nested) == "env"
    System.delete_env("CONFIG_TEST")
    Application.delete_env(:util, :config_test)
  end

  test "config/3 raises if config isn't found" do
    assert_raise ArgumentError, fn -> Util.config(:util, :config_test, :nested) end
  end

  def log_duration_test(arg_1, arg_2) do
    send(self(), {:log_duration_test, arg_1, arg_2})
    []
  end

  describe "log_duration/2" do
    test "logs how long a function took, and returns the result" do
      old_level = Logger.level()

      on_exit(fn ->
        Logger.configure(level: old_level)
      end)

      Logger.configure(level: :info)

      log =
        capture_log(fn ->
          assert Util.log_duration(__MODULE__, :log_duration_test, [1, 2]) == []
          assert_receive {:log_duration_test, 1, 2}
        end)

      assert log =~ "duration="
    end
  end

  describe "time_is_greater_or_equal?/2" do
    test "properly determines if date is before reference date" do
      day = Util.to_local_time(~N[2020-07-13T00:00:00])
      ten_days_later = Util.to_local_time(~N[2020-07-23T00:00:00])
      assert time_is_greater_or_equal?(ten_days_later, day) == true
      assert time_is_greater_or_equal?(day, ten_days_later) == false
    end
  end

  describe "parse/1" do
    test "returns error" do
      assert Util.parse(%{}) == {:error, :invalid_date}
    end

    test "parses destructured date" do
      assert Util.parse(%{
               "year" => 2020,
               "month" => 10,
               "day" => 15,
               "hour" => 10,
               "minute" => 21,
               "am_pm" => "AM"
             }) == ~N[2020-10-15 10:21:00]
    end

    test "parses DateTime" do
      dt = %DateTime{
        year: 2020,
        month: 9,
        day: 1,
        hour: 13,
        minute: 26,
        second: 8,
        utc_offset: -18_000,
        std_offset: 3_600,
        time_zone: "Etc/UTC",
        zone_abbr: "EDT"
      }

      assert DateTime.to_naive(Util.parse(dt)) == ~N[2020-09-01 13:26:08]
    end
  end
end
