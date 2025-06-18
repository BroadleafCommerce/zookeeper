# Update Steps

- `mvn clean install`
- `FULLY_QUALIFIED_MAIN_IMAGE_TAG=repository.broadleafcommerce.com:5001/broadleaf/zookeeper:3.8.4-test BUILD_AND_LOAD_LOCAL_PLATFORM_ONLY=true docker buildx bake -f docker-bake.hcl`


## Update Notes & Considerations

- The Official Apache Zookeeper Source is maintained here: https://github.com/apache/zookeeper
- The "Official Zookeeper" Docker Image is maintained separately by the Docker Community Here: https://github.com/31z4/zookeeper-docker and not part of the source Apache repo
- As part of any update process, it would be beneficial to refer back to the the zookeeper docker repo for any changes that may need to also be applied to the Dockerfile maintained in this repo (e.g. ENV, entrypoint script changes, etc...) when applicable