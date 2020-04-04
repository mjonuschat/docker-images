cmake_minimum_required(VERSION 3.10)

project(DockerImages)

# CMake Configuration
set(CMAKE_SKIP_INSTALL_RULES True)
string(TIMESTAMP BUILD_DATE "%Y%m%d")

# Ubuntu versions for which to build images
list(APPEND UBUNTU_VERSIONS bionic)
list(SORT UBUNTU_VERSIONS)
list(GET UBUNTU_VERSIONS -1 LATEST_UBUNTU_VERSION)
set(FOCAL_TAG "devel")
set(BIONIC_TAG "latest")

# Ruby versions for which to build images
list(APPEND RUBY_VERSIONS 2.7.1 2.6.6 2.5.8 2.4.10)
list(SORT RUBY_VERSIONS)
list(REVERSE RUBY_VERSIONS)

# Build Rails images for the latest two Ruby versions
list(SUBLIST RUBY_VERSIONS 0 2 RAILS_VERSIONS)

add_custom_target("build-baseimages")
add_custom_target("tag-baseimages" DEPENDS build-baseimages)
add_custom_target("push-baseimages" DEPENDS tag-baseimages)

add_custom_target("build-passenger" DEPENDS build-baseimages)
add_custom_target("tag-passenger" DEPENDS build-passenger)
add_custom_target("push-passenger" DEPENDS tag-passenger)

add_custom_target("build-rails" DEPENDS build-passenger)
add_custom_target("tag-rails" DEPENDS build-rails)
add_custom_target("push-rails" DEPENDS tag-rails)

add_custom_target("build" ALL DEPENDS build-baseimages build-passenger build-rails)
add_custom_target("tag" ALL DEPENDS tag-baseimages tag-passenger tag-rails)
add_custom_target("release" ALL DEPENDS push-baseimages push-passenger push-rails)

foreach(RELEASE IN LISTS UBUNTU_VERSIONS)
    string(TOUPPER ${RELEASE} RELEASE_U)
    set(UBUNTU_RELEASE_NAME "${RELEASE}")
    set(UBUNTU_RELEASE_TAG "${${RELEASE_U}_TAG}")
    configure_file(src/baseimage.json.in build/baseimage-${UBUNTU_RELEASE_NAME}.json)

    add_custom_target(
        build-baseimage-${UBUNTU_RELEASE_NAME}
        COMMENT "Building baseimage for Ubuntu „${UBUNTU_RELEASE_NAME}”"
        COMMAND packer build build/baseimage-${UBUNTU_RELEASE_NAME}.json > build/baseimage-${UBUNTU_RELEASE_NAME}.log
    )
    add_custom_target(
        tag-baseimage-${UBUNTU_RELEASE_NAME}
        COMMENT "Tagging baseimage for Ubuntu „${UBUNTU_RELEASE_NAME}”"
        COMMAND docker tag mjonuschat/baseimage:${UBUNTU_RELEASE_NAME} mjonuschat/baseimage:${UBUNTU_RELEASE_NAME}-${BUILD_DATE}  > /dev/null
        COMMAND docker tag mjonuschat/baseimage:${UBUNTU_RELEASE_NAME} mjonuschat/baseimage:${UBUNTU_RELEASE_TAG} > /dev/null
        DEPENDS build-baseimage-${UBUNTU_RELEASE_NAME}
    )
    add_custom_target(
        push-baseimage-${UBUNTU_RELEASE_NAME}
        COMMENT "Pushing baseimage for Ubuntu „${UBUNTU_RELEASE_NAME}”"
        COMMAND docker push mjonuschat/baseimage:${UBUNTU_RELEASE_NAME}-${BUILD_DATE} > /dev/null
        COMMAND docker push mjonuschat/baseimage:${UBUNTU_RELEASE_NAME} > /dev/null
        COMMAND docker push mjonuschat/baseimage:${UBUNTU_RELEASE_TAG} > /dev/null
        DEPENDS tag-baseimage-${UBUNTU_RELEASE_NAME}
    )
    add_dependencies("build-baseimages" build-baseimage-${UBUNTU_RELEASE_NAME})
    add_dependencies("tag-baseimages" tag-baseimage-${UBUNTU_RELEASE_NAME})
    add_dependencies("push-baseimages" push-baseimage-${UBUNTU_RELEASE_NAME})

    foreach(RUBY_VERSION_FULL IN LISTS RUBY_VERSIONS)
        string(REGEX REPLACE "^([0-9]+\.[0-9]+)\.[0-9]+$" "\\1" RUBY_VERSION_SHORT ${RUBY_VERSION_FULL})
        string(REGEX REPLACE "^([0-9]+)\.([0-9]+)\.[0-9]+$" "\\1\\2" RUBY_VERSION_ID ${RUBY_VERSION_FULL})
        configure_file(src/passenger.json.in build/passenger-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME}.json)
        add_custom_target(
            build-passenger-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME}
            COMMENT "Building Passenger image for Ruby ${RUBY_VERSION_FULL} on Ubuntu „${UBUNTU_RELEASE_NAME}”"
            COMMAND packer build build/passenger-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME}.json  > build/passenger-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME}.log
            DEPENDS build-baseimage-${UBUNTU_RELEASE_NAME}
        )
        add_custom_target(
            tag-passenger-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME}
            COMMENT "Tagging Passenger image for Ruby ${RUBY_VERSION_FULL} on Ubuntu „${UBUNTU_RELEASE_NAME}”"
            COMMAND docker tag mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME} mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME}-${BUILD_DATE} > /dev/null
            COMMAND docker tag mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME} mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME} > /dev/null
            COMMAND docker tag mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME} mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_TAG} > /dev/null
            COMMAND docker tag mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME} mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_SHORT}-${UBUNTU_RELEASE_NAME} > /dev/null
            COMMAND docker tag mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME} mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_SHORT}-${UBUNTU_RELEASE_TAG} > /dev/null
            COMMAND docker tag mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME} mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${UBUNTU_RELEASE_NAME} > /dev/null
            COMMAND docker tag mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME} mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${UBUNTU_RELEASE_TAG} > /dev/null
            DEPENDS build-passenger-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME}
        )
        add_custom_target(
            push-passenger-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME}
            COMMENT "Pushing Passenger image for Ruby ${RUBY_VERSION_FULL} on Ubuntu „${UBUNTU_RELEASE_NAME}”"
            COMMAND docker push mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME}-${BUILD_DATE} > /dev/null
            COMMAND docker push mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME} > /dev/null
            COMMAND docker push mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_TAG} > /dev/null
            COMMAND docker push mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_SHORT}-${UBUNTU_RELEASE_NAME} > /dev/null
            COMMAND docker push mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_SHORT}-${UBUNTU_RELEASE_TAG} > /dev/null
            COMMAND docker push mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${UBUNTU_RELEASE_NAME} > /dev/null
            COMMAND docker push mjonuschat/passenger-ruby${RUBY_VERSION_ID}:${UBUNTU_RELEASE_TAG} > /dev/null
            DEPENDS tag-passenger-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME}
        )
        add_dependencies("build-passenger" build-passenger-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME})
        add_dependencies("tag-passenger" tag-passenger-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME})
        add_dependencies("push-passenger" push-passenger-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME})

        if ("${RUBY_VERSION_FULL}" IN_LIST RAILS_VERSIONS)
            configure_file(src/rails.json.in build/rails-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME}.json)

            add_custom_target(
                build-rails-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME}
                COMMENT "Building Rails image for Ruby ${RUBY_VERSION_FULL} on Ubuntu „${UBUNTU_RELEASE_NAME}”"
                COMMAND packer build build/rails-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME}.json > build/rails-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME}.log
                DEPENDS build-passenger-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME}
            )
            add_custom_target(
                tag-rails-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME}
                COMMENT "Tagging Rails image for Ruby ${RUBY_VERSION_FULL} on Ubuntu „${UBUNTU_RELEASE_NAME}”"
                COMMAND docker tag mjonuschat/rails-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME} mjonuschat/rails-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME}-${BUILD_DATE} > /dev/null
                COMMAND docker tag mjonuschat/rails-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME} mjonuschat/rails-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME} > /dev/null
                COMMAND docker tag mjonuschat/rails-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME} mjonuschat/rails-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_TAG} > /dev/null
                COMMAND docker tag mjonuschat/rails-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME} mjonuschat/rails-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_SHORT}-${UBUNTU_RELEASE_NAME} > /dev/null
                COMMAND docker tag mjonuschat/rails-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME} mjonuschat/rails-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_SHORT}-${UBUNTU_RELEASE_TAG} > /dev/null
                COMMAND docker tag mjonuschat/rails-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME} mjonuschat/rails-ruby${RUBY_VERSION_ID}:${UBUNTU_RELEASE_NAME} > /dev/null
                COMMAND docker tag mjonuschat/rails-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME} mjonuschat/rails-ruby${RUBY_VERSION_ID}:${UBUNTU_RELEASE_TAG} > /dev/null
                DEPENDS build-rails-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME}
            )
            add_custom_target(
                push-rails-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME}
                COMMENT "Pushing Rails image for Ruby ${RUBY_VERSION_FULL} on Ubuntu „${UBUNTU_RELEASE_NAME}”"
                COMMAND docker push mjonuschat/rails-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME}-${BUILD_DATE} > /dev/null
                COMMAND docker push mjonuschat/rails-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_NAME} > /dev/null
                COMMAND docker push mjonuschat/rails-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_FULL}-${UBUNTU_RELEASE_TAG} > /dev/null
                COMMAND docker push mjonuschat/rails-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_SHORT}-${UBUNTU_RELEASE_NAME} > /dev/null
                COMMAND docker push mjonuschat/rails-ruby${RUBY_VERSION_ID}:${RUBY_VERSION_SHORT}-${UBUNTU_RELEASE_TAG} > /dev/null
                COMMAND docker push mjonuschat/rails-ruby${RUBY_VERSION_ID}:${UBUNTU_RELEASE_NAME} > /dev/null
                COMMAND docker push mjonuschat/rails-ruby${RUBY_VERSION_ID}:${UBUNTU_RELEASE_TAG} > /dev/null
                DEPENDS tag-rails-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME}
            )

            add_dependencies("build-rails" build-rails-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME})
            add_dependencies("tag-rails" tag-rails-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME})
            add_dependencies("push-rails" push-rails-ruby${RUBY_VERSION_ID}-${UBUNTU_RELEASE_NAME})
        endif()
    endforeach(RUBY_VERSION_FULL)
endforeach(RELEASE)