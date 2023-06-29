defmodule Mpesa.RequestManager do
  use HTTPoison.Base

  alias Mpesa.Auth

  require Logger

  @user_agent "mpesa"

  def process_request_url(url), do: url

  def process_request_body(body) do
    body |> Jason.encode!()
  end

  def process_response_body(body) do
    body |> Jason.decode!()
  end

  def process_response(%HTTPoison.Response{status_code: code, body: body}) when code in 200..299 do
    IO.inspect body
    body
  end

  def process_response(%HTTPoison.Response{body: body}) do
    IO.inspect(body)
    error = body |> Map.get("error", body |> Map.get("errors", ""))
    error
  end

  def process_response(%HTTPoison.Error{reason: reason}) do
    IO.inspect("reason #{reason}")
    Logger.error("Mpesa.RequestManager #{inspect(reason)}")
    reason
  end

  @doc """
  Register validation and callback urls
  """
  def register_urls(instance, validation_url, confirmation_url, response_type \\ "Cancelled") do
    body = %{
      "ResponseType" => response_type,
      "ConfirmationURL" => confirmation_url,
      "ValidationURL" => validation_url,
      "ShortCode" => Mpesa.config(instance, :short_code)
      # "ShortCode" => "5005893"
    }

    headers = set_header(instance, [])
    url = Mpesa.url("/mpesa/c2b/v2/registerurl")
    IO.puts("Mpesa:Url #{url}")

    __MODULE__.post(url, body, headers)
  end

  @doc """
   Msisdn - should have no + before the number country code
   amount - should have cent. ie 200.00
  """
  def c2b_simulate(instance, msisdn, amount, reference) do
    body = %{
      "ShortCode" => Mpesa.config(instance, :short_code),
      "CommandID" => "CustomerPayBillOnline",
      "Amount" => amount,
      "Msisdn" => msisdn,
      "BillRefNumber" => reference
    }

    headers = set_header(instance, [])
    url = Mpesa.url("/mpesa/c2b/v1/simulate")

    __MODULE__.post(url, body, headers)
  end

  @doc """
    Command_id: use "SalaryPayment", "BusinessPayment", "PromotionPayment"
    amount: eg 200
    partyb: your number eg 254718101442

  """
  def b2c(config, command_id, amount, partyb, remarks, result_url, timeout_url, occasion \\ nil) do
    body = %{
      "InitiatorName" => Mpesa.config(config, :initiator_name),
      "SecurityCredential" => Mpesa.Auth.security(config),
      "CommandID" => command_id,
      "Amount" => amount,
      "PartyA" => Mpesa.config(config, :short_code),
      "PartyB" => partyb,
      "Remarks" => remarks,
      "QueueTimeOutURL" => timeout_url,
      "ResultURL" => result_url,
      "Occasion" => occasion
    }

    url = Mpesa.url("/mpesa//b2c/v1/paymentrequest")
    headers = set_header(config, [])

    __MODULE__.post(url, body, headers)
  end

  @doc """
  Send B2B request
  """
  def b2b(config, command_id, amount, sender_type, partyb, receiver_type, remarks, ref) do
    body = %{
      "Initiator" => Mpesa.config(config, :initiator_name),
      "SecurityCredential" => Auth.security(config),
      "CommandID" => command_id,
      "Amount" => amount,
      "PartyA" => Mpesa.config(config, :shortcode),
      "SenderIdentifier" => sender_type,
      "PartyB" => partyb,
      "RecieverIdentifierType" => receiver_type,
      "Remarks" => remarks,
      "QueueTimeOutURL" => Mpesa.config(config, :timeout_url),
      "ResultURL" => Mpesa.config(config, :result_url),
      "AccountReference" => ref
    }

    __MODULE__.post("/b2b/v1/paymentrequest", body)
  end

  @doc """
  # Example: Mpesa.StkPush.process_request(mpesa, "+254702997218", 30, "BLAH", "BLAH", "http://postb.in/b/96hb2jqi")
  """
  def stk_push(instance, mssidn, amount, reference, description, callback_url) do
    timestamp = get_timestamp()
    shortcode = Mpesa.config(instance, :short_code)
    pass_key = Mpesa.config(instance, :pass_key)

    body = %{
      "BusinessShortCode" => shortcode,
      "Password" => :base64.encode(shortcode <> pass_key <> timestamp),
      "Timestamp" => timestamp,
      "TransactionType" => "CustomerPayBillOnline",
      "Amount" => amount,
      "PhoneNumber" => mssidn,
      "PartyA" => mssidn,
      "PartyB" => shortcode,
      "CallBackURL" => callback_url,
      "AccountReference" => reference,
      "TransactionDesc" => description
    }

    headers = set_header(instance, [])
    url = Mpesa.url("/mpesa/stkpush/v1/processrequest")

    __MODULE__.post(url, body, headers)
  end

  def query(instance, checkout_requestId) do
    pass_key = Mpesa.config(instance, :pass_key)
    timestamp = get_timestamp()
    shortcode = Mpesa.config(instance, :short_code)

    body = %{
      "BusinessShortCode" => shortcode,
      "Password" => :base64.encode(shortcode <> pass_key <> timestamp),
      "Timestamp" => timestamp,
      "CheckoutRequestID" => checkout_requestId
    }

    headers = set_header(instance, [])
    url = Mpesa.url("/mpesa/stkpushquery/v1/query")

    __MODULE__.post(url, body, headers)
  end

  def get_timestamp do
    Timex.local()
    |> Timex.format!("{YYYY}{0M}{0D}{h24}{m}{s}")
  end

  @doc """
  Attach a user agent parameter for all the requests
  """
  def set_header(app, headers) do
    headers =
      Keyword.put(headers, :"User-Agent", @user_agent)
      |> Keyword.put(:"Content-Type", "application/json")

    case Auth.generate_token(app) do
      {:ok, auth} ->
        Keyword.put(headers, :Authorization, "Bearer #{auth["access_token"]}")

      {:error, %HTTPoison.Response{body: body}} ->
        IO.inspect("Error occured #{body}")
        headers
    end
  end
end
