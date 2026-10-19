package com.exploreworld.sticker;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class StickerServiceTest {

    private static final Long USER_ID = 1L;

    @Mock
    private StickerRepository repository;

    @InjectMocks
    private StickerService service;

    @Test
    void add_savesStickerForCountryAndCity() {
        when(repository.existsByUserIdAndCountryIgnoreCaseAndCityIgnoreCase(USER_ID, "İtalya", "Roma"))
                .thenReturn(false);
        when(repository.save(any(Sticker.class))).thenAnswer(inv -> inv.getArgument(0));

        StickerResponse response = service.add(USER_ID,
                new StickerRequest(" İtalya ", " Roma ", LocalDate.of(2026, 10, 3), "Harikaydı"));

        assertThat(response.country()).isEqualTo("İtalya");
        assertThat(response.city()).isEqualTo("Roma");
        assertThat(response.visitedOn()).isEqualTo(LocalDate.of(2026, 10, 3));
        assertThat(response.note()).isEqualTo("Harikaydı");
    }

    @Test
    void add_blankCityAndNote_areStoredAsNull() {
        when(repository.existsByUserIdAndCountryIgnoreCaseAndCityIsNull(USER_ID, "Japonya"))
                .thenReturn(false);
        when(repository.save(any(Sticker.class))).thenAnswer(inv -> inv.getArgument(0));

        service.add(USER_ID, new StickerRequest("Japonya", "  ", null, "   "));

        ArgumentCaptor<Sticker> captor = ArgumentCaptor.forClass(Sticker.class);
        verify(repository).save(captor.capture());
        assertThat(captor.getValue().getCity()).isNull();
        assertThat(captor.getValue().getNote()).isNull();
        assertThat(captor.getValue().getUserId()).isEqualTo(USER_ID);
    }

    @Test
    void add_duplicateCountry_throwsConflict() {
        when(repository.existsByUserIdAndCountryIgnoreCaseAndCityIsNull(USER_ID, "Fransa"))
                .thenReturn(true);

        assertThatThrownBy(() -> service.add(USER_ID, new StickerRequest("Fransa", null, null, null)))
                .isInstanceOfSatisfying(ResponseStatusException.class,
                        e -> assertThat(e.getStatusCode()).isEqualTo(HttpStatus.CONFLICT));

        verify(repository, never()).save(any());
    }

    @Test
    void list_returnsStickersOfUser() {
        when(repository.findByUserIdOrderByCreatedAtDesc(USER_ID)).thenReturn(List.of(
                new Sticker(USER_ID, "İtalya", "Roma", null, null),
                new Sticker(USER_ID, "Fransa", null, null, "Paris")));

        List<StickerResponse> result = service.list(USER_ID);

        assertThat(result).hasSize(2);
        assertThat(result.get(0).country()).isEqualTo("İtalya");
        assertThat(result.get(1).note()).isEqualTo("Paris");
    }

    @Test
    void delete_ownSticker_deletesIt() {
        Sticker sticker = new Sticker(USER_ID, "İtalya", null, null, null);
        when(repository.findByIdAndUserId(5L, USER_ID)).thenReturn(Optional.of(sticker));

        service.delete(USER_ID, 5L);

        verify(repository).delete(sticker);
    }

    @Test
    void delete_otherUsersSticker_throwsNotFound() {
        when(repository.findByIdAndUserId(5L, USER_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.delete(USER_ID, 5L))
                .isInstanceOfSatisfying(ResponseStatusException.class,
                        e -> assertThat(e.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND));

        verify(repository, never()).delete(any());
    }
}
