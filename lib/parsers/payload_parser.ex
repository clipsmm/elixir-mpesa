defmodule Mpesa.Parsers.PayloadParser do
  alias Mpesa.Parsers.{C2bParser}
  def parse(:c2b, paylaod), do: C2bParser.parse(paylaod)

  def parse(:b2c, paylaod) do
  end

  def parse(:b2b, paylaod) do
  end

  def parse(:balance, paylaod) do
  end
end
