package com.exploreworld.trip;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TripServiceTest {

    private static final Long USER_ID = 10L;
    private static final Long TRIP_ID = 1L;

    @Mock
    private TripRepository trips;

    @Mock
    private TripStopRepository stopRepository;

    @InjectMocks
    private TripService service;

    // ---------- yardımcılar ----------

    private Trip tripWithDays(int dayCount) {
        Trip trip = new Trip(USER_ID, "Roma Gezisi", "Roma", "İtalya");
        for (int i = 1; i <= dayCount; i++) {
            trip.addDay(i);
        }
        return trip;
    }

    /** Gündeki durakları ekler ve test için sahte id verir (gerçekte id'yi veritabanı üretir). */
    private void addStops(TripDay day, long firstId, String... names) {
        long id = firstId;
        for (String name : names) {
            day.addStop(name, null, null, null);
            TripStop stop = day.getStops().get(day.getStops().size() - 1);
            ReflectionTestUtils.setField(stop, "id", id++);
        }
    }

    private void tripExists(Trip trip) {
        when(trips.findByIdAndUserId(TRIP_ID, USER_ID)).thenReturn(Optional.of(trip));
    }

    private List<String> names(TripDay day) {
        return day.getStops().stream().map(TripStop::getName).toList();
    }

    private List<Integer> orders(TripDay day) {
        return day.getStops().stream().map(TripStop::getSortOrder).toList();
    }

    // ---------- testler ----------

    @Test
    @DisplayName("create: istenen gün sayısı kadar gün oluşturur")
    void create_createsRequestedNumberOfDays() {
        when(trips.saveAndFlush(any(Trip.class))).thenAnswer(inv -> inv.getArgument(0));

        TripResponse response = service.create(USER_ID,
                new TripCreateRequest("Roma Gezisi", "Roma", "İtalya", 3));

        assertThat(response.title()).isEqualTo("Roma Gezisi");
        assertThat(response.days()).hasSize(3);
        assertThat(response.days().get(0).dayNumber()).isEqualTo(1);
        assertThat(response.days().get(2).dayNumber()).isEqualTo(3);
    }

    @Test
    @DisplayName("get: başkasının veya olmayan seyahat için 404 döner")
    void get_unknownOrForeignTrip_throwsNotFound() {
        when(trips.findByIdAndUserId(TRIP_ID, USER_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.get(USER_ID, TRIP_ID))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    @DisplayName("addStop: durağı doğru güne ekler")
    void addStop_addsStopToCorrectDay() {
        Trip trip = tripWithDays(2);
        tripExists(trip);

        service.addStop(USER_ID, TRIP_ID, new StopRequest(2, "Kolezyum", null, null, "Sabah git"));

        TripDay day2 = trip.getDays().get(1);
        assertThat(names(day2)).containsExactly("Kolezyum");
        assertThat(trip.getDays().get(0).getStops()).isEmpty();
    }

    @Test
    @DisplayName("addStop: olmayan gün için 404 döner")
    void addStop_unknownDay_throwsNotFound() {
        tripExists(tripWithDays(2));

        assertThatThrownBy(() -> service.addStop(USER_ID, TRIP_ID,
                new StopRequest(5, "Pantheon", null, null, null)))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    @DisplayName("moveStop: aynı gün içinde sıralamayı değiştirir ve yeniden numaralandırır")
    void moveStop_withinSameDay_reordersAndRenumbers() {
        Trip trip = tripWithDays(1);
        TripDay day1 = trip.getDays().get(0);
        addStops(day1, 100L, "A", "B", "C");
        tripExists(trip);

        // C durağını 1. sıraya al
        service.moveStop(USER_ID, TRIP_ID, 102L, new MoveRequest(1, 1));

        assertThat(names(day1)).containsExactly("C", "A", "B");
        assertThat(orders(day1)).containsExactly(1, 2, 3);
    }

    @Test
    @DisplayName("moveStop: başka güne taşır, iki günü de yeniden numaralandırır")
    void moveStop_toAnotherDay_renumbersBothDays() {
        Trip trip = tripWithDays(2);
        TripDay day1 = trip.getDays().get(0);
        TripDay day2 = trip.getDays().get(1);
        addStops(day1, 100L, "A", "B");
        addStops(day2, 200L, "X");
        tripExists(trip);

        // A durağını 2. günün 2. sırasına taşı
        service.moveStop(USER_ID, TRIP_ID, 100L, new MoveRequest(2, 2));

        assertThat(names(day1)).containsExactly("B");
        assertThat(orders(day1)).containsExactly(1);
        assertThat(names(day2)).containsExactly("X", "A");
        assertThat(orders(day2)).containsExactly(1, 2);
    }

    @Test
    @DisplayName("deleteStop: durağı siler ve kalanları yeniden numaralandırır")
    void deleteStop_removesStopAndRenumbers() {
        Trip trip = tripWithDays(1);
        TripDay day1 = trip.getDays().get(0);
        addStops(day1, 100L, "A", "B", "C");
        tripExists(trip);

        service.deleteStop(USER_ID, TRIP_ID, 101L);

        assertThat(names(day1)).containsExactly("A", "C");
        assertThat(orders(day1)).containsExactly(1, 2);
        verify(stopRepository).delete(any(TripStop.class));
    }
}
