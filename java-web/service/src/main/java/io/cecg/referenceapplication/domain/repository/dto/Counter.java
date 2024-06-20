package io.cecg.referenceapplication.domain.repository.dto;


import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Column;
import jakarta.persistence.Table;

@Entity
@Table(name = "counter")
public class Counter {
    @Id
    private String name;

    @Column(nullable = false)
    private Long counter;

    public Counter() {
    }

    public Counter(String name, Long counter) {
        this.name = name;
        this.counter = counter;
    }

    public String getName() {
        return name;
    }

    public Counter setName(String name) {
        this.name = name;
        return this;
    }

    public Long getCounter() {
        return counter;
    }

    public Counter setCounter(Long counter) {
        this.counter = counter;
        return this;
    }

    public void incrementCounter() {
        this.counter++;
    }

    @Override
    public String toString() {
        return "Counter{" +
                "name='" + name + '\'' +
                ", counter=" + counter +
                '}';
    }
}