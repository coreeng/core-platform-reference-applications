package io.cecg.reference;

import io.cucumber.junit.Cucumber;
import io.cucumber.junit.CucumberOptions;
import org.junit.runner.RunWith;

@RunWith(Cucumber.class)
@CucumberOptions( plugin = { "json:build/cucumber-reports/integration-test-report.json" } )
public class Tests {
}