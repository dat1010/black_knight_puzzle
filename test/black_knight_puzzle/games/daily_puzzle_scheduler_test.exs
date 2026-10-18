defmodule BlackKnightPuzzle.Games.DailyPuzzleSchedulerTest do
  use BlackKnightPuzzle.DataCase

  alias BlackKnightPuzzle.Games
  alias BlackKnightPuzzle.Games.DailyPuzzleScheduler

  test "is not started when disabled" do
    assert :ignore = DailyPuzzleScheduler.init(enabled: false)
  end

  test "generates today's puzzle and the days ahead" do
    pid =
      start_supervised!(
        {DailyPuzzleScheduler,
         name: nil, enabled: true, days_ahead: 1, interval_ms: :timer.hours(1)}
      )

    today = Date.utc_today()
    assert DailyPuzzleScheduler.run_now(pid) == [today, Date.add(today, 1)]
    assert Games.get_daily_puzzle(today)
    assert Games.get_daily_puzzle(Date.add(today, 1))
  end
end
