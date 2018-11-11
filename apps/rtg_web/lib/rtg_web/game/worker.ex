defmodule RtgWeb.Game.Worker do
  @moduledoc false

  alias RtgWeb.Endpoint
  alias RtgWeb.Game

  require Logger

  use GenServer

  @type id :: binary

  @type player :: %{pid: pid, monitor: reference, hp: integer}

  @type t :: %{id: id, players: [player]}

  def start_link(arg), do: GenServer.start_link(__MODULE__, arg, name: Game.worker_name(arg[:id]))

  @impl GenServer
  def init(arg) do
    Process.send_after(self(), :check_started, 1_000)
    {:ok, %{id: arg[:id], players: []}}
  end

  @impl GenServer
  def handle_cast({:join, player}, state) do
    Logger.debug(inspect({__MODULE__, :join, player}))
    player = put_in(player[:monitor], Process.monitor(player.pid))
    player = put_in(player[:hp], 100)
    state = if started?(state), do: state, else: update_in(state.players, &[player | &1])
    {:noreply, state}
  end

  def handle_cast({:move_to, player, {x, y}, anim_end}, state) do
    Logger.debug(inspect({__MODULE__, :move_to, player, {x, y}, anim_end}))

    Endpoint.broadcast!("game:" <> state.id, "move_to", %{
      player: player |> :erlang.term_to_binary([:compressed]) |> Base.encode64(),
      dest: %{x: x, y: y},
      anim_end: anim_end
    })

    {:noreply, state}
  end

  def handle_cast({:damage, player, damage_point}, state) do
    Logger.debug(inspect({__MODULE__, :damage, player, damage_point}))

    state =
      Map.update!(state, :players, fn players ->
        for player_ <- players do
          if player_.pid == player.pid do
            %{player_ | hp: player_.hp - 10}
          else
            player_
          end
        end
      end)

    Endpoint.broadcast!("game:" <> state.id, "damage", %{
      player:
        Enum.filter(state.players, fn player_ -> player_.pid == player.pid end)
        |> Enum.at(0)
        |> :erlang.term_to_binary([:compressed])
        |> Base.encode64()
    })

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, _object, _reason}, state) do
    Logger.debug(inspect({__MODULE__, :DOWN, ref}))
    {:noreply, state}
  end

  def handle_info(:check_started, state) do
    Logger.debug(inspect({__MODULE__, :check_started}))

    if started?(state) do
      {:noreply, state}
    else
      Enum.each(state.players, &send(&1.pid, :game_not_started))
      {:stop, :normal, state}
    end
  end

  @spec started?(t) :: boolean
  defp started?(state), do: length(state.players) == 2
end
