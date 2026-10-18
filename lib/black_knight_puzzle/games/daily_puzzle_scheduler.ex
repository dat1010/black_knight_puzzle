defmodule BlackKnightPuzzle.Games.DailyPuzzleScheduler do
  @moduledoc """
  Generates upcoming daily puzzles in the background, so a visitor never waits
  on the solver.

  On start, and then every `:interval_ms`, it makes sure puzzles exist for
  today and the next `:days_ahead` days (UTC). Generating a date that already
  exists is a no-op, and if two app instances race on the same date, the
  unique index on `puzzle_date` keeps one row.
  """

  use GenServer

  require Logger

  alias BlackKnightPuzzle.Games

  @default_days_ahead 2
  @default_interval_ms :timer.hours(1)

  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Runs one generation pass now and returns the dates it ensured.
  """
  def run_now(server \\ __MODULE__) do
    GenServer.call(server, :run, :infinity)
  end

  @impl true
  def init(opts) do
    config = Keyword.merge(Application.get_env(:black_knight_puzzle, __MODULE__, []), opts)

    if Keyword.get(config, :enabled, true) do
      state = %{
        days_ahead: Keyword.get(config, :days_ahead, @default_days_ahead),
        interval_ms: Keyword.get(config, :interval_ms, @default_interval_ms)
      }

      send(self(), :run)
      {:ok, state}
    else
      :ignore
    end
  end

  @impl true
  def handle_info(:run, state) do
    ensure_upcoming(state)
    Process.send_after(self(), :run, state.interval_ms)
    {:noreply, state}
  end

  @impl true
  def handle_call(:run, _from, state) do
    {:reply, ensure_upcoming(state), state}
  end

  defp ensure_upcoming(state) do
    Games.ensure_daily_puzzles(Date.utc_today(), state.days_ahead)
  rescue
    error ->
      Logger.error("Daily puzzle generation failed: " <> Exception.message(error))
      []
  end
end
