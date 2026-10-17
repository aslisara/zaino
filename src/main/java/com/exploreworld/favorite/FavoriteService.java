package com.exploreworld.favorite;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class FavoriteService {

    private final FavoriteRepository repository;

    public FavoriteService(FavoriteRepository repository) {
        this.repository = repository;
    }

    @Transactional
    public FavoriteResponse add(Long userId, FavoriteRequest request) {
        if (repository.existsByUserIdAndTypeAndNameAndCity(
                userId, request.type(), request.name(), request.city())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Bu favori zaten ekli");
        }
        Favorite saved = repository.saveAndFlush(
                new Favorite(userId, request.type(), request.name(), request.city(), request.country()));
        return FavoriteResponse.from(saved);
    }

    @Transactional(readOnly = true)
    public List<FavoriteResponse> list(Long userId) {
        return repository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(FavoriteResponse::from)
                .toList();
    }

    @Transactional
    public void delete(Long userId, Long id) {
        Favorite favorite = repository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Favori bulunamadı"));
        repository.delete(favorite);
    }
}