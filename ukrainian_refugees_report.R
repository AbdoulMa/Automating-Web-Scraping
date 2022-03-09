library(tidyverse)

# Data file path 
overall_refugees_file <- "data/overall_refugees.csv"

# Retrieve daily data published by UNHCR 
daily_overall_refugees <- rjson::fromJSON(file = "https://data2.unhcr.org/population/get/sublocation?geo_id=0&forcesublocation=1&widget_id=283557&sv_id=54&color=%233c8dbc&color2=%23303030&population_group=5460") %>% 
  pluck("data") %>% 
  tibble::enframe() %>% 
  unnest_wider(value) %>% 
  select(-where(is.list)) %>% 
  relocate(c("date", "individuals"), .after =  "admin_level") %>% 
  mutate(date = readr::parse_date(date), 
         across(.cols = c("individuals", "centroid_lon", "centroid_lat", "month", "year", "population_group_id", "individuals_type","demography_type", "households","numChildren"), readr::parse_double, .names ="{.col}" )) 
# Retrieve former data 
if (fs::file_exists(overall_refugees_file)) {
  overall_refugees <- readr::read_csv(overall_refugees_file)
} else {
  overall_refugees <- daily_overall_refugees
}

# Check if new daily data 
daily_refugees <- daily_overall_refugees %>%
  anti_join(overall_refugees, by = c("geomaster_id", "date"))


if (nrow(daily_refugees) != 0) {
  write_csv(daily_refugees, here::here("data",paste0(format(lubridate::today(), "%Y_%m_%d"),".csv")))
  overall_refugees <- bind_rows(overall_refugees, daily_refugees)
}

# Arrange by date
overall_refugees <- overall_refugees %>% 
  arrange(date)

# Update data file 
write_csv(overall_refugees, "data/overall_refugees.csv")
