package io.cecg.reference;


import io.cucumber.core.logging.Logger;
import io.cucumber.core.logging.LoggerFactory;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import io.restassured.response.Response;
import io.restassured.specification.RequestSpecification;
import org.apache.commons.lang3.SystemUtils;
import org.apache.http.HttpStatus;
import org.json.JSONException;
import org.json.JSONObject;
import org.skyscreamer.jsonassert.JSONAssert;
import org.skyscreamer.jsonassert.JSONCompareMode;
import org.skyscreamer.jsonassert.JSONParser;

import java.util.UUID;

import static io.restassured.RestAssured.given;
import static org.apache.http.HttpStatus.SC_OK;
import static org.junit.Assert.assertEquals;

public class Stepdefs {
    private static final Logger LOG = LoggerFactory.getLogger(Stepdefs.class);

    private final String baseUri = SystemUtils.getEnvironmentVariable("SERVICE_ENDPOINT", "http://localhost:8080");
    private RequestSpecification request;
    private Response response;
    private String unique_id;

    @Given("^a rest service$")
    public void aRestService() {
        request = given().baseUri(baseUri);
    }

    @Given("^a random UUID$")
    public void a_random_uuid() {
        unique_id = UUID.randomUUID().toString();
    }


    @When("^I call the hello world endpoint$")
    public void i_call_the_hello_world_endpoint() {
        System.out.printf("Hitting endpoint: %s%n", baseUri);
        response = request.when().get("/hello");
    }

    @When("^I call the get counter with the random UUID")
    public void i_call_get_counter_uuid() {
        System.out.printf("Hitting endpoint: %s%n", baseUri);
        response = request.when().get("/counter/" + unique_id);
    }

    @When("^I call the get counter with the name '(.*)'$")
    public void i_call_get_counter_with_name(String name) {
        System.out.printf("Hitting endpoint: %s%n", baseUri);
        response = request.when().get("/counter/" + name);
    }

    @When("^I call the put counter with the random UUID")
    public void i_call_put_counter_uuid() {
        System.out.printf("Hitting endpoint: %s%n", baseUri);
        response = request.when().put("/counter/" + unique_id);
    }

    @When("^I call the swagger endpoint$")
    public void i_call_the_swagger_endpoint() {
        System.out.printf("Hitting endpoint: %s%n", baseUri);
        response = request.when().get("/swagger-ui/index.html");
    }

    @When("^I call the downstream endpoint with (\\d+) seconds of response delay$")
    public void i_call_delay_endpoint(int delaySeconds) {
        System.out.printf("Hitting endpoint: %s%n", baseUri);
        response = request.when().get(String.format("/delay/%d", delaySeconds));
    }

    @When("^I call the status endpoint with (\\d+) status code")
    public void i_call_status_endpoint(int status) {
        System.out.printf("Hitting endpoint: %s%n", baseUri);
        response = request.when().get(String.format("/status/%d", status));
    }

    @Then("^an ok response is returned$")
    public void an_ok_response_is_returned() {
        assertEquals("Non 200 status code received", SC_OK, response.statusCode());
    }

    @Then("^an '(\\d+)' response is returned$")
    public void a_response_is_returned(int status) {
        assertEquals("Non " + status + " status code received", status, response.statusCode());
    }

    @Then("^the response body field '(.*)' is equal to '(.*)'")
    public void compare_body_field(String field, String value) throws JSONException {

        JSONObject resp = (JSONObject) JSONParser.parseJSON(response.getBody().asPrettyString());
        assertEquals("Field value not matching", String.valueOf(resp.get(field)), value);

    }

    @Then("^the response body is$")
    public void a_response_is_returned(String body) throws JSONException {
        JSONAssert.assertEquals(body, response.getBody().asPrettyString(), JSONCompareMode.STRICT);
    }
}