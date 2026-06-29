# Update Steps

- It seems to help to do these steps in iTerm outside of IntelliJ (this was the only way I was able to complete the test suite ~20 min)
- Use JDK 17
- `export JAVA_HOME=$(/usr/libexec/java_home)`
- `mvn clean install` (this will include tests -- after tests are confirmed you can run `mvn clean install -DskipTests` for any additional build needs)
- For local testing: `FULLY_QUALIFIED_MAIN_IMAGE_TAG=repository.broadleafcommerce.com:5001/broadleaf/zookeeper:3.8.6-wolfi-5 BUILD_AND_LOAD_LOCAL_PLATFORM_ONLY=true docker buildx bake -f docker-bake.hcl`
- For release: `FULLY_QUALIFIED_MAIN_IMAGE_TAG=repository.broadleafcommerce.com:5001/broadleaf/zookeeper:3.8.6-wolfi-5 docker buildx bake --builder blc-devops-multiplatform-builder -f docker-bake.hcl --push` (Increment the `r1` to a higher value if only changing java or os deps without changing app, jre, or os versions).

## Update Notes & Considerations

- **Wolfi Base Image:** We have transitioned to a Wolfi-based environment for better security and minimal footprint.
    - The `docker-bake.hcl` file now includes a `BASE_IMAGE` variable which defaults to `repository.broadleafcommerce.com:5001/broadleaf/zookeeper-base:wolfi-5`.
- The Official Apache Zookeeper Source is maintained here: https://github.com/apache/zookeeper
- The "Official Zookeeper" Docker Image is maintained separately by the Docker Community Here: https://github.com/31z4/zookeeper-docker and not part of the source Apache repo
- As part of any update process, it would be beneficial to refer back to the the zookeeper docker repo for any changes that may need to also be applied to the Dockerfile maintained in this repo (e.g. ENV, entrypoint script changes, etc...) when applicable
