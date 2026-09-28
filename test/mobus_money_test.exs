defmodule MobusMoneyTest do
  # Not async: these tests mutate the global :ex_money application env.
  use ExUnit.Case, async: false

  describe "ensure_fx_disabled!/0" do
    @tag :fx_guard
    test "raises, naming the missing setting, when the config is unset" do
      saved = Application.get_env(:ex_money, :auto_start_exchange_rate_service)
      Application.delete_env(:ex_money, :auto_start_exchange_rate_service)

      assert_raise ArgumentError, ~r/auto_start_exchange_rate_service/, fn ->
        MobusMoney.ensure_fx_disabled!()
      end

      on_exit(fn ->
        if saved == :unset do
          Application.delete_env(:ex_money, :auto_start_exchange_rate_service)
        else
          Application.put_env(:ex_money, :auto_start_exchange_rate_service, saved)
        end
      end)
    end

    @tag :fx_guard
    test "raises when the config is explicitly true" do
      saved = Application.get_env(:ex_money, :auto_start_exchange_rate_service)
      Application.put_env(:ex_money, :auto_start_exchange_rate_service, true)

      assert_raise ArgumentError, ~r/auto_start_exchange_rate_service/, fn ->
        MobusMoney.ensure_fx_disabled!()
      end

      on_exit(fn ->
        if saved == :unset do
          Application.delete_env(:ex_money, :auto_start_exchange_rate_service)
        else
          Application.put_env(:ex_money, :auto_start_exchange_rate_service, saved)
        end
      end)
    end

    test "returns :ok when the config is explicitly false" do
      saved = Application.get_env(:ex_money, :auto_start_exchange_rate_service)
      Application.put_env(:ex_money, :auto_start_exchange_rate_service, false)

      assert MobusMoney.ensure_fx_disabled!() == :ok

      on_exit(fn ->
        if saved == :unset do
          Application.delete_env(:ex_money, :auto_start_exchange_rate_service)
        else
          Application.put_env(:ex_money, :auto_start_exchange_rate_service, saved)
        end
      end)
    end
  end
end
