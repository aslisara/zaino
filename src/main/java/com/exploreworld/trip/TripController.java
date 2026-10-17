package com.exploreworld.trip;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/trips")
public class TripController {

    private final TripService service;

    public TripController(TripService service) {
        this.service = service;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public TripResponse create(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody TripCreateRequest request) {
        return service.create(userId(jwt), request);
    }

    @GetMapping
    public List<TripSummary> list(@AuthenticationPrincipal Jwt jwt) {
        return service.list(userId(jwt));
    }

    @GetMapping("/{id}")
    public TripResponse get(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id) {
        return service.get(userId(jwt), id);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id) {
        service.delete(userId(jwt), id);
    }

    @PostMapping("/{id}/stops")
    @ResponseStatus(HttpStatus.CREATED)
    public TripResponse addStop(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id,
                                @Valid @RequestBody StopRequest request) {
        return service.addStop(userId(jwt), id, request);
    }

    @PutMapping("/{id}/stops/{stopId}/move")
    public TripResponse moveStop(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id,
                                 @PathVariable Long stopId, @Valid @RequestBody MoveRequest request) {
        return service.moveStop(userId(jwt), id, stopId, request);
    }

    @DeleteMapping("/{id}/stops/{stopId}")
    public TripResponse deleteStop(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id,
                                   @PathVariable Long stopId) {
        return service.deleteStop(userId(jwt), id, stopId);
    }

    private Long userId(Jwt jwt) {
        return Long.valueOf(jwt.getSubject());
    }
}