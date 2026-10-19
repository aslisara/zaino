package com.exploreworld.ai;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AiUsageServiceTest {

    @Mock
    private AiUsageRepository repository;

    @Test
    void consume_underLimit_passes() {
        when(repository.increment(eq(1L), any(LocalDate.class))).thenReturn(2);
        AiUsageService service = new AiUsageService(repository, 3);

        assertDoesNotThrow(() -> service.consume(1L));
    }

    @Test
    void consume_atLimit_stillPasses() {
        when(repository.increment(eq(1L), any(LocalDate.class))).thenReturn(3);
        AiUsageService service = new AiUsageService(repository, 3);

        assertDoesNotThrow(() -> service.consume(1L));
    }

    @Test
    void consume_overLimit_throwsTooManyRequests() {
        when(repository.increment(eq(1L), any(LocalDate.class))).thenReturn(4);
        AiUsageService service = new AiUsageService(repository, 3);

        ResponseStatusException ex = assertThrows(ResponseStatusException.class, () -> service.consume(1L));

        assertEquals(HttpStatus.TOO_MANY_REQUESTS, ex.getStatusCode());
    }
}
