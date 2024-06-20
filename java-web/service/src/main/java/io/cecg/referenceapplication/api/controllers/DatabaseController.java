package io.cecg.referenceapplication.api.controllers;

import io.cecg.referenceapplication.api.exceptions.ApiException;
import io.cecg.referenceapplication.domain.repository.CounterRepository;
import io.cecg.referenceapplication.domain.repository.dto.Counter;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController(value = "database")
@ResponseBody
public class DatabaseController {
    private final CounterRepository counterRepository;

    public DatabaseController(CounterRepository counterRepository) {
        this.counterRepository = counterRepository;
    }

    @GetMapping("/counter/{name}")
    public Counter getCounter(@PathVariable(value = "name") String name) throws ApiException {
        return findByName(name);
    }

    @PutMapping("/counter/{name}")
    public Counter putCounter(@PathVariable(value = "name") String name) throws ApiException {
        Counter counter = findByName(name);
        counter.incrementCounter();
        counterRepository.save(counter);
        return counter;
    }

    private Counter findByName(String name) {
        return Optional.ofNullable(counterRepository.findCounterByName(name))
                .orElse(new Counter(name, 0L));
    }
}