package com.exploreworld.trip;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "trip_days")
public class TripDay {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "trip_id", nullable = false)
    private Trip trip;

    @Column(name = "day_number", nullable = false)
    private int dayNumber;

    @OneToMany(mappedBy = "day", cascade = CascadeType.ALL)
    @OrderBy("sortOrder ASC")
    private List<TripStop> stops = new ArrayList<>();

    protected TripDay() {
        // JPA için gerekli
    }

    TripDay(Trip trip, int dayNumber) {
        this.trip = trip;
        this.dayNumber = dayNumber;
    }

    public TripStop addStop(String name, Double latitude, Double longitude, String note) {
        TripStop stop = new TripStop(this, stops.size() + 1, name, latitude, longitude, note);
        stops.add(stop);
        return stop;
    }

    public Long getId() { return id; }
    public Trip getTrip() { return trip; }
    public int getDayNumber() { return dayNumber; }
    public List<TripStop> getStops() { return stops; }
}