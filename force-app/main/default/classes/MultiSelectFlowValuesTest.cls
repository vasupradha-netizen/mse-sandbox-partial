/**
 * Test class for MultiSelectFlowValues.
 * Ensures the functionality of the MultiSelectFlowValues class is working as expected.
 */
@isTest
private class MultiSelectFlowValuesTest {

    /**
     * Test case to validate the CheckValues method with a valid input.
     */
    @isTest
    static void testCheckValuesWithValidInput() {
        // Test input: List containing a semicolon-separated string
        List<String> inputValues = new List<String>{'A;B;C;D'};

        // Expected output: Nested list with split values
        List<List<String>> expectedOutput = new List<List<String>>{
            new List<String>{'A', 'B', 'C', 'D'}
        };

        // Call the method and store the result
        List<List<String>> result = MultiSelectFlowValues.CheckValues(inputValues);

        // Validate the result matches the expected output
        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(expectedOutput, result, 'The output does not match the expected nested list.');
    }

    /**
     * Test case to validate the CheckValues method with an empty input list.
     */
    @isTest
    static void testCheckValuesWithEmptyInput() {
        // Test input: Empty list
        List<String> inputValues = new List<String>();

        // Call the method and store the result
        List<List<String>> result = MultiSelectFlowValues.CheckValues(inputValues);

        // Validate the result is null
        System.assertEquals(null, result, 'Result should be null for an empty input list.');
    }

    /**
     * Test case to validate the CheckValues method with a single empty string as input.
     */
    @isTest
    static void testCheckValuesWithEmptyString() {
        // Test input: List containing an empty string
        List<String> inputValues = new List<String>{''};

        // Expected output: Nested list with an empty string
        List<List<String>> expectedOutput = new List<List<String>>{
            new List<String>{''}
        };

        // Call the method and store the result
        List<List<String>> result = MultiSelectFlowValues.CheckValues(inputValues);

        // Validate the result matches the expected output
        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(expectedOutput, result, 'The output does not match the expected nested list for an empty string.');
    }
}