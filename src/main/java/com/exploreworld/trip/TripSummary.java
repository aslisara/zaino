package com.exploreworld.trip;

public record TripSummary(Long id, String title, String city, String country, int dayCount) {

    public static TripSummary from(Trip t) {
        return new TripSummary(t.getId(), t.getTitle(), t.getCity(), t.getCountry(), t.getDays().size());
    }
}