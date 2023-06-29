defmodule Mpesa.Account do
  @moduledoc """
  Module to work with mpesa account
  """

  alias Mpesa
  alias Mpesa.Auth

  @doc """
  Get balance_queue_time_out_url, from the config file
  """
  def get_balance_queue_time_out_url do
    Application.get_env(:mpesa, :balance_queue_time_out_url)
  end

  @doc """
  Get balance_result_url, from the config file
  """
  def get_balance_result_url do
    Application.get_env(:mpesa, :balance_result_url)
  end

  @spec balance(integer(), String.t()) :: term
  def balance(identifier_type, remarks) do
    body = %{
      "Initiator" => Mpesa.get_initiator_name(),
      "CommandID" => "AccountBalance",
      "SecurityCredential" => Auth.security(),
      "PartyA" => Mpesa.get_short_code(),
      "IdentifierType" => identifier_type,
      "Remarks" => remarks
    }

    Mpesa.post("/accountbalance/v1/query", body: Jason.encode!(body))
    |> Mpesa.process_response()
  end
end
