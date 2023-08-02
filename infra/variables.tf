
variable "stage" {
  type        = string
  description = "Deployment Stage"
}


variable "data_source" {
  type = map(object({
    source_bucket        = string
    source_key           = string
    target_dir           = string
    glue_cleaning_script = string
  }))

  default = {
    "fund_details" : {
      "source_bucket" : "data-engineering-technical-task"
      "source_key" : "data/outputs/Fund_Details.csv"
      "target_dir" : "raw/fund_details"
      "glue_cleaning_script" : "fund_details.py"
    },
    "fund_prices" : {
      "source_bucket" : "data-engineering-technical-task"
      "source_key" : "data/outputs/Fund_Prices.csv"
      "target_dir" : "raw/fund_prices"
      "glue_cleaning_script" : "fund_prices.py"
    }
  }
}