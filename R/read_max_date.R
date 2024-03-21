

read_max_date <- function() {
  cs <- Sys.getenv("DATALAKE_CONNECTION_STRING") |> 
    stringr::str_split(";") |>
    unlist() |>
    stringr::str_split_fixed("=", 2) |>
    as.data.frame() |>
    tidyr::pivot_wider(names_from = V1, values_from = V2)
  
  endpoint <- sprintf(
    "%s://%s.blob.%s",
    cs$DefaultEndpointsProtocol,
    cs$AccountName,
    cs$EndpointSuffix
  )
  
  proxy_list <- curl::ie_get_proxy_for_url()
  
  httr::set_config(
    httr::use_proxy(
      url = regmatches(proxy_list, regexpr("[^;]+", proxy_list)),
      auth = "ntlm"
    )
  )
  
  med_layer <- "silver"
  blob_path <- "Public/published_discharge_delays_community/part-00000-310a0ab2-a1de-4e5f-83cd-e1bc44fd62e2-c000.snappy.parquet"
  file_path <- tempfile()
  
  cont <- AzureStor::blob_endpoint(endpoint, key = cs$AccountKey) |>
    AzureStor::storage_container(med_layer)
  
  AzureStor::storage_download(
    cont,
    blob_path,
    dest = file_path
  )
  
  df <- arrow::read_parquet(file_path)
  
  return(format(max(df$Date), "%d %b %Y"))
}