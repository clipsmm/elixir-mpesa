defmodule Mpesa do
  alias Mpesa.Auth
  alias Mpesa.RequestManager
  require Logger

  @dev_url "https://sandbox.safaricom.co.ke"

  @live_url "https://api.safaricom.co.ke"

  @config Application.get_env(:kashier, :mpesa)

  def instance(app \\ nil) do
    app_name = if is_nil(app), do: get_in(@config, [:default]), else: app
    app_version = get_in(@config, [:apps, app_name])

    Map.merge(base_config(), app_version)
  end

  def base_config do
    cert_path = if is_live(), do: "mpesa/keys/live_cert.cer", else: "mpesa/keys/sandox_cert.cer"

    %{
      cert_path: cert_path
    }
  end

  @doc """
  get the appropriate url from the configuration files.
  """
  def get_api_url() do
    if is_live(), do: @live_url, else: @dev_url
  end

  def is_live do
    get_in(@config, [:live])
  end

  def url(url) do
    get_api_url() <> url
  end

  def config(instance, key, default \\ nil) do
    Map.get(instance, key, default)
  end

  @doc """
  Send Mpesa STK push request

  ## Examples

      iex> Mpesa.stk_push(:c2b, "254702997218", 30, "BLAH", "BLAH", "https://3040-197-237-129-248.eu.ngrok.io")
  """
  def stk_push(app, msisdn, amount, ref, notes, callback_url) do
    instance(app)
      |> RequestManager.stk_push(msisdn, amount, ref, notes, callback_url)
  end

  def register_urls(app, validation_url, confirmation_url) do
    instance(app)
      |> RequestManager.register_urls(validation_url, confirmation_url)
  end
end
