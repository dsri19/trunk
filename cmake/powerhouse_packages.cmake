# rename DAF library to PWHDAF in order to avoid conflicts with DG which somehow uses a
# version of DAF which is not binary compatible to our one
set_target_properties(daf PROPERTIES OUTPUT_NAME "pwhdaf")

# Create a PowerHouse package
RTT_PKG_CREATE(powerhouse_libraries ${PROJECT_BINARY_DIR}/packages/powerhouse_libraries)
RTT_PKG_REGISTER_TARGET(powerhouse_libraries commons)
RTT_PKG_REGISTER_TARGET(powerhouse_libraries http)
RTT_PKG_REGISTER_TARGET(powerhouse_libraries daf)

