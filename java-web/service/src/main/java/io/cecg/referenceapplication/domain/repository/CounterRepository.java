package io.cecg.referenceapplication.domain.repository;

import io.cecg.referenceapplication.domain.repository.dto.Counter;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface CounterRepository extends JpaRepository<Counter,Long>, JpaSpecificationExecutor<Counter> {
    Counter findCounterByName(String name);
}