package com.exploreworld.user;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AccountServiceTest {

    @Mock
    private AccountRepository repository;

    @InjectMocks
    private AccountService service;

    @Test
    void deleteAccount_removesStickersAndUser() {
        when(repository.deleteUser(7L)).thenReturn(1);

        assertDoesNotThrow(() -> service.deleteAccount(7L));

        verify(repository).deleteStickers(7L);
        verify(repository).deleteUser(7L);
    }

    @Test
    void deleteAccount_unknownUser_throwsNotFound() {
        when(repository.deleteUser(99L)).thenReturn(0);

        ResponseStatusException ex = assertThrows(ResponseStatusException.class, () -> service.deleteAccount(99L));

        assertEquals(HttpStatus.NOT_FOUND, ex.getStatusCode());
    }
}
