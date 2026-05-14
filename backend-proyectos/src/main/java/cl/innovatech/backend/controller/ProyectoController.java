package cl.innovatech.backend.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import cl.innovatech.backend.model.Avance;
import cl.innovatech.backend.model.Proyecto;
import cl.innovatech.backend.service.AvanceService;
import cl.innovatech.backend.service.ProyectoService;
import jakarta.validation.Valid;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/v1")
public class ProyectoController {

    private final ProyectoService proyectoService;
    private final AvanceService avanceService;

    public ProyectoController(ProyectoService proyectoService, AvanceService avanceService) {
        this.proyectoService = proyectoService;
        this.avanceService = avanceService;
    }

    @GetMapping("/proyectos")
    public ResponseEntity<List<Proyecto>> listarProyectos() {
        return ResponseEntity.ok(proyectoService.listar());
    }

    @PostMapping("/proyectos")
    public ResponseEntity<Proyecto> crearProyecto(@Valid @RequestBody Proyecto proyecto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(proyectoService.guardar(proyecto));
    }

    @DeleteMapping("/proyectos/{id}")
    public ResponseEntity<Void> eliminarProyecto(@PathVariable Long id) {
        proyectoService.eliminar(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/avances")
    public ResponseEntity<List<Avance>> listarAvances() {
        return ResponseEntity.ok(avanceService.listar());
    }

    @GetMapping("/proyectos/{proyectoId}/avances")
    public ResponseEntity<List<Avance>> listarAvancesPorProyecto(@PathVariable Long proyectoId) {
        return ResponseEntity.ok(avanceService.listarPorProyecto(proyectoId));
    }

    @PostMapping("/proyectos/{proyectoId}/avances")
    public ResponseEntity<Avance> crearAvance(@PathVariable Long proyectoId,
                                              @Valid @RequestBody Avance avance) {
        return ResponseEntity.status(HttpStatus.CREATED).body(avanceService.guardar(proyectoId, avance));
    }

    @DeleteMapping("/avances/{id}")
    public ResponseEntity<Void> eliminarAvance(@PathVariable Long id) {
        avanceService.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}
