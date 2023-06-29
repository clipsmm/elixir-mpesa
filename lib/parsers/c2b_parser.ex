defmodule Mpesa.Parsers.C2bParser do
  def parse(%{"Body" => body}) do
    cond do
      get_in(body, ["stkCallback", "ResultCode"]) == 0 -> success_data(body)
      true -> failed_data(body)
    end
  end

  def success_data(data) do
    result =
      data
      |> get_in(["stkCallback", "CallbackMetadata", "Item"])
      |> Enum.into(%{}, fn i ->
        {i["Name"], get_in(i, ["Value"])}
      end)
      |> Map.merge(%{"CheckoutRequestID" => get_in(data, ["stkCallback", "CheckoutRequestID"])})

    {:ok, result}
  end

  def failed_data(data) do
    data
    {:error, data}
  end

  def get_params(params, :stk) do
    timestamp = params["TransactionDate"]
    source = params["PhoneNumber"]

    %{
      "rct_no" => params["MpesaReceiptNumber"],
      "amount" => params["Amount"],
      "date_paid" => Timex.parse!("#{timestamp}", "{YYYY}{0M}{D}{h24}{m}{s}"),
      "source" => "#{source}",
      "channel" => "mpesa",
      "ref" => "#{source}",
      "customer" => nil
    }
  end

  def get_params(params, :confirmation) do
    %{
      "rct_no" => params["TransID"],
      "amount" => params["TransAmount"],
      "paid_at" => Timex.parse!("#{params["TransTime"]}", "{YYYY}{0M}{D}{h24}{m}{s}"),
      "source" => params["MSISDN"],
      "channel" => params["BusinessShortCode"],
      "customer" => "",
      "bill_no" => params["BillRefNumber"],
      "org_balance" => params["OrgAccountBalance"]
    }
  end

  defp get_customer(params) do
    params["FirstName"] <> " " <> params["LastName"]
  end
end
