defmodule Mpesa.Auth do
  alias Mpesa
  alias Mpesa.PublicKey
  use HTTPoison.Base

  require Logger

  defstruct access_token: nil, expires_in: nil

  @doc """
   get the certificate path from your config file
  """
  def get_certificate_path do
    Application.get_env(:mpesa, :certificate_path)
  end

  @doc """
  create the required base64 string to use with the API
  """
  def create_base64_key(consumer_key, consumer_secret) do
    (consumer_key <> ":" <> consumer_secret) |> Base.encode64()
  end

  @doc """
  Attach a authcode here
  """
  def header_token(app) do
    consumer_key = Mpesa.config(app, :consumer_key)
    consumer_secret = Mpesa.config(app, :consumer_secret)
    create_base64_key(consumer_key, consumer_secret)
  end

  def process_request_url(url), do: url

  def process_response_body(body) do
    body |> Jason.decode!()
  end

  @doc """
  Make an http call to the API and fetch the access token
  """
  def generate_token(app) do
    token = header_token(app)
    url = Mpesa.url("/oauth/v1/generate?grant_type=client_credentials")
    headers = [Authorization: "Basic #{token}"]

    case get(url, headers, []) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body} = resp} ->
        cond do
          status_code == 200 -> {:ok, body}
          true -> {:error, resp}
        end

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Mpesa.Auth.generate_token #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  This function will generate a securty key to use with SecurityCredential
  """
  def security(app) do
    plain_text = Mpesa.config(app, :initiator_password)

    Mpesa.config(app, :cert_path)
    |> PublicKey.extract_public_from()
    |> PublicKey.generate_base64_cypherstring(plain_text)
  end
end
