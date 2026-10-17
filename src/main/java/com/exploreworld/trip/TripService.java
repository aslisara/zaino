package com.exploreworld.trip;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class TripService {

    private final TripRepository trips;
    private final TripStopRepository stopRepository;

    public TripService(TripRepository trips, TripStopRepository stopRepository) {
        this.trips = trips;
        this.stopRepository = stopRepository;
    }

    @Transactional
    public TripResponse create(Long userId, TripCreateRequest request) {
        Trip trip = new Trip(userId, request.title(), request.city(), request.country());
        for (int i = 1; i <= request.dayCount(); i++) {
            trip.addDay(i);
        }
        return TripResponse.from(trips.saveAndFlush(trip));
    }

    @Transactional(readOnly = true)
    public List<TripSummary> list(Long userId) {
        return trips.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(TripSummary::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public TripResponse get(Long userId, Long tripId) {
        return TripResponse.from(findTrip(userId, tripId));
    }

    @Transactional
    public void delete(Long userId, Long tripId) {
        trips.delete(findTrip(userId, tripId));
    }

    @Transactional
    public TripResponse addStop(Long userId, Long tripId, StopRequest request) {
        Trip trip = findTrip(userId, tripId);
        TripDay day = findDay(trip, request.dayNumber());
        day.addStop(request.name(), request.latitude(), request.longitude(), request.note());
        trips.flush();
        return TripResponse.from(trip);
    }

    @Transactional
    public TripResponse moveStop(Long userId, Long tripId, Long stopId, MoveRequest request) {
        Trip trip = findTrip(userId, tripId);
        TripStop stop = findStop(trip, stopId);
        TripDay from = stop.getDay();
        TripDay to = findDay(trip, request.dayNumber());

        from.getStops().remove(stop);
        List<TripStop> target = to.getStops();
        int index = Math.min(request.position() - 1, target.size());
        target.add(index, stop);
        stop.setDay(to);

        renumber(from);
        renumber(to);
        trips.flush();
        return TripResponse.from(trip);
    }

    @Transactional
    public TripResponse deleteStop(Long userId, Long tripId, Long stopId) {
        Trip trip = findTrip(userId, tripId);
        TripStop stop = findStop(trip, stopId);
        TripDay day = stop.getDay();

        day.getStops().remove(stop);
        stopRepository.delete(stop);
        renumber(day);
        trips.flush();
        return TripResponse.from(trip);
    }

    private Trip findTrip(Long userId, Long tripId) {
        return trips.findByIdAndUserId(tripId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Seyahat bulunamadı"));
    }

    private TripDay findDay(Trip trip, int dayNumber) {
        return trip.getDays().stream()
                .filter(d -> d.getDayNumber() == dayNumber)
                .findFirst()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Gün bulunamadı"));
    }

    private TripStop findStop(Trip trip, Long stopId) {
        return trip.getDays().stream()
                .flatMap(d -> d.getStops().stream())
                .filter(s -> s.getId().equals(stopId))
                .findFirst()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Durak bulunamadı"));
    }

    private void renumber(TripDay day) {
        List<TripStop> list = day.getStops();
        for (int i = 0; i < list.size(); i++) {
            list.get(i).setSortOrder(i + 1);
        }
    }
}