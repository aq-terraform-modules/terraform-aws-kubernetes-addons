locals {
  # region     = aws_region.current.name
  account_id = data.aws_caller_identity.current.
  region     = data.aws_region.name
}