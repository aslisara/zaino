package com.exploreworld.trip;

import java.time.OffsetDateTime;
import java.util.List;

public record TripResponse(Long id, String title, String city, String country,
                           OffsetDateTime createdAt, List<Day> days) {

    public record Day(int dayNumber, List<Stop> stops) {}

    public record Stop(Long id, int order, String name, Double latitude, Double longitude, String note) {}

    public static TripResponse from(Trip t) {
        List<Day> days = t.getDays().stream()
                .map(d -> new Day(d.getDayNumber(), d.getStops().stream()
                        .map(s -> new Stop(s.getId(), s.getSortOrder(), s.getName(),
                                s.getLatitude(), s.getLongitude(), s.getNote()))
                        .toList()))
                .toList();
        return new TripResponse(t.getId(), t.getTitle(), t.getCity(), t.getCountry(),
                t.getCreatedAt(), days);
    }
}