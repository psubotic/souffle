function(ADD_SOUFFLE_BINARY_TEST TEST_NAME CATEGORY)
    # The naming of the test targets is inconsistent in souffle
    # Keep the file name the same (for now) but rename the rest
    string(REGEX REPLACE "^test_" "" SHORT_TEST_NAME ${TEST_NAME})
    string(REGEX REPLACE "_test$" "" SHORT_TEST_NAME ${SHORT_TEST_NAME})
    set(TARGET_NAME "test_${SHORT_TEST_NAME}")

    add_executable(${TARGET_NAME} ${TEST_NAME}.cpp)
    target_link_libraries(${TARGET_NAME} libsouffle)

    set(QUALIFIED_TEST_NAME ${SHORT_TEST_NAME})
    add_test(NAME ${QUALIFIED_TEST_NAME} COMMAND ${TARGET_NAME})
    set_tests_properties(${QUALIFIED_TEST_NAME} PROPERTIES LABELS "unit_test;${CATEGORY}")
endfunction()

function(RUN_SOUFFLE_TEST_HELPER)
    # PARAM_CATEGORY - e.g. syntactic, example etc.
    # PARAM_TEST_NAME - the name of the test, the short directory name under tests/<category>/<test_name>
    # PARAM_COMPILED - with or without -c
    # PARAM_NEGATIVE - should it fail or not
    # PARAM_MULTI_TEST - used to distinguish "multi-tests", sort of left over from automake
    #                           Basically, the same test dir has multiple sets of facts/outputs
    #                           We should just get rid of this and make multiple tests
    #                           It also means we need to use slightly different naming for tests
    #                           and input paths
    # PARAM_FACTS_DIR_NAME - the name of the "facts" subdirectory in each test.
    #                        Usually just "facts" but can be different when running multi-tests
    cmake_parse_arguments(
        PARAM
        "COMPILED;NEGATIVE;MULTI_TEST" # Options
        "TEST_NAME;CATEGORY;FACTS_DIR_NAME" #Single valued options
        ""
        ${ARGV}
    )

    if (PARAM_COMPILED)
        set(EXTRA_FLAGS "-c")
        set(EXEC_STYLE "compiled")
        set(SHORT_EXEC_STYLE "_c")
    else()
        set(EXEC_STYLE "interpreted")
        set(SHORT_EXEC_STYLE "")
    endif()

    set(INPUT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/${PARAM_TEST_NAME}")
    set(FACTS_DIR "${INPUT_DIR}/${PARAM_FACTS_DIR_NAME}")

    if (PARAM_MULTI_TEST)
        set(DATA_CHECK_DIR "${INPUT_DIR}/${PARAM_FACTS_DIR_NAME}")
        set(MT_EXTRA_SUFFIX "_${PARAM_FACTS_DIR_NAME}")
    else()
        set(DATA_CHECK_DIR "${INPUT_DIR}")
        set(MT_EXTRA_SUFFIX "")
    endif()

    set(OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/${PARAM_TEST_NAME}${MT_EXTRA_SUFFIX}_${EXEC_STYLE}")
    # Give the test a name which has good info about it when running
    # People can then search for the test by the name, or the labels we create
    set(QUALIFIED_TEST_NAME ${PARAM_CATEGORY}/${PARAM_TEST_NAME}${MT_EXTRA_SUFFIX}${SHORT_EXEC_STYLE})

    if(PARAM_NEGATIVE)
        set(POS_LABEL "negative")
    else()
        set(POS_LABEL "positive")
    endif()


    # Set up the test directory
    add_test(NAME ${QUALIFIED_TEST_NAME}_setup
             COMMAND "${CMAKE_SOURCE_DIR}/cmake/setup_test_dir.sh" "${DATA_CHECK_DIR}" "${OUTPUT_DIR}" "${PARAM_TEST_NAME}")
    set_tests_properties(${QUALIFIED_TEST_NAME}_setup PROPERTIES
                         LABELS "${PARAM_CATEGORY};${EXEC_STYLE};${POS_LABEL};integration")

    # Run souffle
    add_test(NAME ${QUALIFIED_TEST_NAME} COMMAND
             sh -c "$<TARGET_FILE:souffle> ${EXTRA_FLAGS} \\
                                            -D '${OUTPUT_DIR}' \\
                                            -F '${FACTS_DIR}' \\
                                           '${INPUT_DIR}/${PARAM_TEST_NAME}.dl' \\
                                            1> '${OUTPUT_DIR}/${PARAM_TEST_NAME}.out' \\
                                            2> '${OUTPUT_DIR}/${PARAM_TEST_NAME}.err'")
    set_tests_properties(${QUALIFIED_TEST_NAME} PROPERTIES
                         LABELS "${PARAM_CATEGORY};${EXEC_STYLE};${POS_LABEL};integration"
                         DEPENDS ${QUALIFIED_TEST_NAME}_setup)

    # Compare stdout/stderr
    add_test(NAME ${QUALIFIED_TEST_NAME}_compare_std_outputs
             COMMAND "${CMAKE_SOURCE_DIR}/cmake/check_std_outputs.sh" "${OUTPUT_DIR}" "${PARAM_TEST_NAME}")
    set_tests_properties(${QUALIFIED_TEST_NAME}_compare_std_outputs PROPERTIES
                         LABELS "${PARAM_CATEGORY};${EXEC_STYLE};${POS_LABEL};integration"
                         DEPENDS ${QUALIFIED_TEST_NAME})

    if (PARAM_NEGATIVE)
        # Mark the souffle run as "will fail" for negative tests
        set_tests_properties(${QUALIFIED_TEST_NAME} PROPERTIES WILL_FAIL TRUE)
    else()
        add_test(NAME ${QUALIFIED_TEST_NAME}_compare_csv
                 COMMAND "${CMAKE_SOURCE_DIR}/cmake/check_test_results.sh" "${OUTPUT_DIR}")
        set_tests_properties(${QUALIFIED_TEST_NAME}_compare_csv PROPERTIES
                            LABELS "${PARAM_CATEGORY};${EXEC_STYLE};${POS_LABEL};integration"
                            DEPENDS ${QUALIFIED_TEST_NAME})
    endif()

endfunction()

function(RUN_SOUFFLE_TEST)
    run_souffle_test_helper(${ARGV})
    run_souffle_test_helper(${ARGV} COMPILED)
endfunction()

function(POSITIVE_SOUFFLE_TEST TEST_NAME CATEGORY)
    run_souffle_test(TEST_NAME ${TEST_NAME}
                     CATEGORY ${CATEGORY}
                     FACTS_DIR_NAME "facts")
endfunction()

function(NEGATIVE_SOUFFLE_TEST TEST_NAME CATEGORY)
    run_souffle_test(NEGATIVE
                     TEST_NAME ${TEST_NAME}
                     CATEGORY ${CATEGORY}
                     FACTS_DIR_NAME "facts")
endfunction()

function(POSITIVE_SOUFFLE_MULTI_TEST)
    cmake_parse_arguments(
        PARAM
        ""
        "TEST_NAME;CATEGORY" #Single valued options
        "FACTS_DIR_NAMES"
        ${ARGV}
    )

    foreach(FACTS_DIR_NAME ${PARAM_FACTS_DIR_NAMES})
        run_souffle_test(TEST_NAME ${PARAM_TEST_NAME}
                         MULTI_TEST
                         CATEGORY ${PARAM_CATEGORY}
                         FACTS_DIR_NAME ${FACTS_DIR_NAME})
    endforeach()
endfunction()
