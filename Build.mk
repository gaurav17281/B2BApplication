###########################################################################################################
###########################################################################################################
##	The make file contains targets for building the debug, enterprise and appstore builds. xcodebuild 	 ##
## 	commands are used to first archive and then create the IPA using the archive. Invoke distclean       ##
##  before invoking the build target to make sure we remove any previously generated artifacts.          ##
###########################################################################################################
###########################################################################################################

include buildConfiguration.mk

# versioning
MAKEFILE_VERSION := 3.0

# exposed by bamboo
WORKING_DIRECTORY := ${bamboo_working_directory}

# for local testing
ifeq (${WORKING_DIRECTORY},)
WORKING_DIRECTORY := ${PWD}/../bamboo_working_directory
endif

# Place all the build files outside of ~/Library/Developer/...
DERIVED_DATA := ${WORKING_DIRECTORY}/DerivedData
DEFAULT_CONFIG := appone
IS_BETA_BUILD := NO


ifeq (${config},)
config := ${DEFAULT_CONFIG}
endif


.PHONY: build
build: distclean config build-app export
	@set -e; \
	echo "EXPORT_SYMBOL = ${EXPORT_SYMBOL}"; \
	echo "Build Success !";

.PHONY: config
config:
# Default configuration is Beta/Enterpise
	@set -e;
ifeq (${config},appone)
BUNDLE_IDENTIFIER := $(BUNDLE_IDENTIFIER_APP_ONE)
UUID_PROFILE := ${UUID_APP_ONE}
else ifeq (${config},apptwo)
BUNDLE_IDENTIFIER := $(BUNDLE_IDENTIFIER_APP_TWO)
UUID_PROFILE := ${UUID_APP_TWO}
else ifeq (${config},appthree)
BUNDLE_IDENTIFIER := $(BUNDLE_IDENTIFIER_APP_THREE)
UUID_PROFILE := ${UUID_APP_THREE}
endif

BUILD_CMD := "xcodebuild -project ${APP_NAME}/${PROJECT}.xcodeproj \
	           -scheme ${SCHEME} \
	           -configuration ${CONFIGURATION_RELEASE} \
	           -archivePath ${WORKING_DIRECTORY}/Archive/${APP_NAME} \
			   -derivedDataPath ${DERIVED_DATA}  \
			   -IDEBuildOperationMaxNumberOfConcurrentCompileTasks=1 \
	           \"PRODUCT_BUNDLE_IDENTIFIER =${BUNDLE_IDENTIFIER}\" \
			   \"PROVISIONING_PROFILE=${UUID_PROFILE}\" \
	           clean archive"



.PHONY: clean
clean: 
	@echo "Cleaning derived data directiory..." ; \
	rm -rf ${DERIVED_DATA} ; \
	echo "Cleaning archive/artifacts directory..." ; \
	rm -rf ${WORKING_DIRECTORY}/Archive ; \
	rm -rf ${WORKING_DIRECTORY}/artifacts ; \
	echo "...Done Cleaning" ;

.PHONY: clean-config
clean-config:
	@set -e;
	@echo "Cleaning up..." ; 

# Cleanup so that things look like a fresh git clone
.PHONY: distclean
distclean: clean
	@echo "Scrubbing working directory..." ; \
	find * -type f \( -name ".DS_Store" -or -name "*.py[co]" \) -delete ; \
	find * -type d \( -name "xcuserdata" -or -name "build" \) -prune -exec rm -rf "{}" \; ; \
	find * -type d -empty -delete ; 


# copy the correct provisioning profiles to the xcode folder 
.PHONY: install-profiles
install-profiles: 
	@set -e;\
	echo "Installing Profiles..." ; \
	cp BuildConfig/${UUID_PROFILE}.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/; \
	echo "Profiles installed...";
	

# echo out the configuration settings for the build
.PHONY: configurationSettings
configurationSettings:
	@set -e; \
	echo "Configuration settings: ";\
	echo "CONFIG  ${config} \n \
		  BUILD_NUMBER  ${BUILD_NUMBER} \n \
		  WORKSPACE  ${PROJECT} \n \
		  SCHEME ${SCHEME} \n \
		  APP_NAME ${APP_NAME}\n \
		  CONFIGURATION_RELEASE ${CONFIGURATION_RELEASE} \n \
		  BUNDLE_IDENTIFIER ${BUNDLE_IDENTIFIER} \n \
		  UUID_PROFILE ${UUID_PROFILE} \n "| column -t; \


# adhoc build
.PHONY: build-app
build-app: install-profiles configurationSettings
	@set -e ; \
	echo "clean and making Archive ...\n" ${BUILD_CMD} ; \
	xcodebuild -project ${APP_NAME}/${PROJECT}.xcodeproj \
	           -scheme ${SCHEME} \
	           -configuration ${CONFIGURATION_RELEASE} \
	           -archivePath ${WORKING_DIRECTORY}/Archive/${APP_NAME} \
			   -derivedDataPath ${DERIVED_DATA}  \
			   -IDEBuildOperationMaxNumberOfConcurrentCompileTasks=1 \
	           "PRODUCT_BUNDLE_IDENTIFIER =${BUNDLE_IDENTIFIER}" \
			   "PROVISIONING_PROFILE=${UUID_PROFILE}";


# export to ipa
.PHONY: export
export: exportDSYM
	@set -e; \
	echo "exporting IPA ..." ; \
	mkdir -p ${WORKING_DIRECTORY}/artifacts ; \
	xcodebuild -exportArchive \
	           -exportOptionsPlist BuildConfig/${EXPORT_PLIST} \
	           -archivePath ${WORKING_DIRECTORY}/Archive/${APP_NAME}.xcarchive \
	           -exportPath ${WORKING_DIRECTORY}/artifacts  ;


# export dSYM file to artifact folder
.PHONY: exportDSYM
exportDSYM: clean-config
	@set -e; \
	echo "export dSYM file ..."; \
	mkdir -p ${WORKING_DIRECTORY}/artifacts; \
	tar -zcf ${WORKING_DIRECTORY}/artifacts/${APP_NAME}.app.dSYM.tar.gz \
		-C ${WORKING_DIRECTORY}/Archive/${APP_NAME}.xcarchive/dSYMs ${APP_NAME}.app.dSYM;
	tar -zcf ${WORKING_DIRECTORY}/artifacts/DocumentProvider.appex.dSYM.tar.gz \
		-C ${WORKING_DIRECTORY}/Archive/${APP_NAME}.xcarchive/dSYMs DocumentProvider.appex.dSYM;
	tar -zcf ${WORKING_DIRECTORY}/artifacts/FileProvider.appex.dSYM.tar.gz \
		-C ${WORKING_DIRECTORY}/Archive/${APP_NAME}.xcarchive/dSYMs FileProvider.appex.dSYM;

