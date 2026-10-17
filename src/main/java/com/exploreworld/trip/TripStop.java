package com.exploreworld.trip;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "trip_stops")
public class TripStop {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "trip_day_id", nullable = false)
    private TripDay day;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

    @Column(nullable = false, length = 200)
    private String name;

    private Double latitude;

    private Double longitude;

    @Column(length = 500)
    private String note;

    protected TripStop() {
        // JPA için gerekli
    }

    TripStop(TripDay day, int sortOrder, String name, Double latitude, Double longitude, String note) {
        this.day = day;
        this.sortOrder = sortOrder;
        this.name = name;
        this.latitude = latitude;
        this.longitude = longitude;
        this.note = note;
    }

    public Long getId() { return id; }
    public TripDay getDay() { return day; }
    public int getSortOrder() { return sortOrder; }
    public String getName() { return name; }
    public Double getLatitude() { return latitude; }
    public Double getLongitude() { return longitude; }
    public String getNote() { return note; }
    void setDay(TripDay day) { this.day = day; }
    void setSortOrder(int sortOrder) { this.sortOrder = sortOrder; }
}