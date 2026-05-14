package cl.innovatech.backend.service;

import java.time.LocalDate;
import java.util.List;

import org.springframework.stereotype.Service;

import cl.innovatech.backend.exception.ResourceNotFoundException;
import cl.innovatech.backend.model.Avance;
import cl.innovatech.backend.model.Proyecto;
import cl.innovatech.backend.repository.AvanceRepository;
import cl.innovatech.backend.repository.ProyectoRepository;

@Service
public class AvanceService {

    private final AvanceRepository avanceRepository;
    private final ProyectoRepository proyectoRepository;

    public AvanceService(AvanceRepository avanceRepository, ProyectoRepository proyectoRepository) {
        this.avanceRepository = avanceRepository;
        this.proyectoRepository = proyectoRepository;
    }

    public List<Avance> listar() {
        return avanceRepository.findAll();
    }

    public List<Avance> listarPorProyecto(Long proyectoId) {
        return avanceRepository.findByProyectoId(proyectoId);
    }

    public Avance guardar(Long proyectoId, Avance avance) {
        Proyecto proyecto = proyectoRepository.findById(proyectoId)
                .orElseThrow(() -> new ResourceNotFoundException("Proyecto no encontrado con id: " + proyectoId));
        if (avance.getFecha() == null) {
            avance.setFecha(LocalDate.now());
        }
        avance.setProyecto(proyecto);
        return avanceRepository.save(avance);
    }

    public void eliminar(Long id) {
        if (!avanceRepository.existsById(id)) {
            throw new ResourceNotFoundException("Avance no encontrado con id: " + id);
        }
        avanceRepository.deleteById(id);
    }
}
