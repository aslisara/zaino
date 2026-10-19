package com.exploreworld.user;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class AccountService {

    private final AccountRepository repository;

    public AccountService(AccountRepository repository) {
        this.repository = repository;
    }

    @Transactional
    public void deleteAccount(Long userId) {
        repository.deleteStickers(userId);
        if (repository.deleteUser(userId) == 0) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Kullanıcı bulunamadı");
        }
    }
}
