package com.mw.app.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import com.mw.app.domain.Salaries;
import com.mw.app.repository.SalariesMapper;

import java.util.List;

@RestController
@RequestMapping("/api")
public class RestAPIController {	
    
    @Autowired
    private SalariesMapper salariesmapper;
    
 	@RequestMapping(value="/get/salary/{emp_no}", method=RequestMethod.GET, produces = "application/json;application/text;charset=utf-8")
 	public List<Salaries> get_salary_emp_no(@PathVariable("emp_no") int emp_no) {
 		
 		List<Salaries> list = null;
 	
 		System.out.println("/api/get/salary/" + emp_no );
 	
 		try { 	        
 			list = salariesmapper.findByEmpno(emp_no);
 			for (Salaries dto : list ) {
 				System.out.println(dto.toString());
 			}
 			return list;
 		} catch(Exception io) {
 			System.out.println(io.toString());			
 			return list;
 		}
 	}
}
